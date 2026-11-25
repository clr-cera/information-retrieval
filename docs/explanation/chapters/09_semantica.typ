#import "../estilo.typ": *

= Busca semântica (`ir/neural.py`, parte 1) <cap-semantica>

== Teoria

=== O limite da busca lexical

O BM25 só encontra documentos que contêm os *mesmos termos* da consulta. Se a consulta diz "heart attack" e o documento diz "myocardial infarction", não há nenhum termo em comum, e o documento recebe score zero, por mais relevante que seja. Esse é o problema da *variação de vocabulário* (sinônimos, paráfrases, termos técnicos versus populares).

=== Embeddings

Um *embedding* é um vetor de números reais que representa o significado de um texto. Ele é produzido por uma rede neural treinada para que textos com significados parecidos tenham vetores próximos, mesmo sem palavras em comum. Comparar consulta e documento vira comparar dois vetores.

=== O modelo: Transformer + pooling

O modelo usado, `sentence-transformers/all-MiniLM-L6-v2`, tem três módulos em sequência:

+ *Transformer* (MiniLM, 6 camadas): divide o texto em *subpalavras* (tokenização WordPiece; por exemplo, `ergothioneine` vira `er`, `##go`, `##thi`, `##one`, `##ine`, e `myocardial infarction` vira `my`, `##oca`, `##rdial`, `in`, `##far`, `##ction`; o `##` indica continuação de palavra) e produz um vetor de 384 números para cada token. Pelo mecanismo de *atenção*, o vetor de cada token leva em conta todos os outros tokens do texto: a mesma palavra recebe vetores diferentes em contextos diferentes.
+ *Pooling* por média (*mean pooling*): tira a média dos vetores de todos os tokens, produzindo um único vetor de 384 números para o texto inteiro.
+ *Normalize*: divide o vetor pelo seu comprimento (norma L2), deixando-o com comprimento 1.

O modelo foi treinado com mais de 1 bilhão de pares de frases, para aproximar os vetores de textos relacionados (pergunta e resposta, título e resumo etc.).

=== Similaridade do cosseno

A similaridade entre dois vetores é o cosseno do ângulo entre eles:
$ cos(bold(q), bold(d)) = (bold(q) dot bold(d)) / (||bold(q)|| dot ||bold(d)||) $

Vale 1 para vetores na mesma direção e 0 para vetores perpendiculares. Como os vetores já estão normalizados (comprimento 1), o denominador vale 1 e *o cosseno é igual ao produto escalar*. Por isso o código só multiplica os vetores.

=== Bi-encoder

O modelo é um *bi-encoder*: consulta e documento passam pelo modelo *separadamente*, cada um gerando o seu vetor. A vantagem é poder calcular os vetores dos documentos uma única vez, antes de qualquer consulta, e guardá-los. Na hora da busca, só a consulta passa pelo modelo; o resto é álgebra. A desvantagem é que o modelo nunca vê consulta e documento juntos (o cross-encoder do reranking faz isso, no @cap-hibrida).

=== Limite de tamanho e truncamento

O Transformer tem um tamanho máximo de entrada: neste modelo, 256 tokens. O que passa disso é *cortado* (truncado) e não influencia o vetor. Os documentos do NFCorpus têm em média 357 tokens (mediana 357, 10% com mais de 504). Assim, *78,8% dos documentos (2.864 de 3.633) são truncados*, e 32% de todos os tokens da coleção não entram nos embeddings. Na prática, o vetor de um documento longo representa o título e o início do resumo.

=== Busca exaustiva

Para cada consulta, calcula-se a similaridade com *todos* os 3.633 documentos. O enunciado permite isso para a busca semântica, porque a coleção é pequena: é uma multiplicação de uma matriz 3.633 × 384 por um vetor, que leva milissegundos. (Em coleções grandes, usam-se índices de vizinhos aproximados, que não são necessários aqui.)

== O código

=== Imports

#tabela(
  (auto, 1fr),
  [*Import*], [*Uso*],
  [`json`], [Gravar e ler `document_ids.json` e `metadata.json` do cache.],
  [`Mapping`, `dataclass`, `Path`, `perf_counter`], [Tipos, classes de resultado, caminhos e medição de tempo.],
  [`numpy as np`], [Matriz de embeddings, produto matriz-vetor e leitura e gravação do `.npy`.],
  [`EMBEDDINGS_DIR` (de `ir.data`)], [Pasta do cache (`data/embeddings`).],
  [`aggregate_metrics`, `compute_per_query_metrics`], [Avaliação.],
  [`SentenceTransformer` e `torch` (dentro do construtor)], [O modelo e a detecção de GPU. Importados só quando um `SemanticIndex` é criado, porque carregar o PyTorch demora alguns segundos; assim, scripts que não usam a busca semântica não pagam esse custo.],
)

=== `rank_documents_by_dot_product`

#funcao("def rank_documents_by_dot_product(query_embedding, document_embeddings, document_ids, top_k=None)")[
  `document_embeddings @ query_embedding` calcula de uma vez os 3.633 produtos escalares, um por documento (a linha $i$ da matriz é o documento `document_ids[i]`). Depois junta cada score ao seu identificador, ordena por score decrescente (desempate por identificador, para ser determinístico) e devolve os `top_k` primeiros.
]

=== `SemanticIndex`

#funcao("class SemanticIndex(documents, model_name, device=None, batch_size=32, cache_dir=EMBEDDINGS_DIR)")[
  O construtor:
  + guarda os textos numa lista, na ordem dos identificadores (essa ordem é a das linhas da matriz);
  + escolhe o dispositivo: `"cuda"` (GPU) se o PyTorch encontrar uma, senão `"cpu"`. Neste trabalho, tudo rodou em CPU;
  + carrega o modelo com `SentenceTransformer(model_name, device=...)`, que o baixa do Hugging Face na primeira vez (fica em `~/.cache/huggingface`);
  + lê a dimensão do embedding (384) e o tamanho máximo de entrada (`max_seq_length`, 256). O `hasattr` trata uma mudança de nome do método entre versões da biblioteca;
  + chama `_load_or_build_embeddings`.
]

#funcao("def _load_or_build_embeddings(self) -> None")[
  Implementa o cache dos embeddings dos documentos em `data/embeddings/<modelo>/`:
  - *Se o cache existe e é válido*, carrega a matriz com `np.load`. Ele só é considerado válido se a lista de documentos, o nome do modelo, a dimensão e a marca de normalização coincidirem com os atuais: isso evita usar vetores de outro modelo ou de outra coleção. O tempo de geração e o número de documentos truncados são lidos do `metadata.json`.
  - *Senão*, conta os documentos truncados, gera os embeddings com `model.encode(textos, batch_size=32, normalize_embeddings=True, convert_to_numpy=True)`, mede o tempo e grava a matriz, a ordem dos documentos e os metadados.

  `batch_size=32` processa 32 documentos por vez: é mais rápido do que um por um, sem usar memória demais. `normalize_embeddings=True` garante vetores de comprimento 1.
]

#atencao(titulo: "O tempo guardado no cache")[
  O tempo registrado no `metadata.json` (154 s) foi medido na primeira geração, quando outros processos rodavam ao mesmo tempo. Uma medição isolada, na mesma máquina (CPU, 8 threads), levou 109,7 s, cerca de 30 ms por documento; os vetores gerados foram idênticos aos do cache.
]

#funcao("def _count_truncated_documents(self) -> int")[
  Usa o tokenizador do próprio modelo, *sem* truncar (`truncation=False`), pedindo o comprimento de cada texto (`return_length=True`), em lotes de 256. Conta quantos passam de `max_seq_length`. O comprimento inclui os dois tokens especiais que o modelo acrescenta (`[CLS]` no início e `[SEP]` no fim).
]

#funcao("def search(self, query, top_k=100) -> tuple[list, float]")[
  Gera o embedding da consulta (uma lista com um único texto, normalizado) e chama `rank_documents_by_dot_product`. Mede o tempo de tudo (gerar o vetor da consulta e ordenar) e devolve o ranking e o tempo. Em média, 0,16 s por consulta, quase todo gasto gerando o vetor.
]

A propriedade `stats` devolve um `SemanticIndexStats` com nome do modelo, dimensão, tamanho máximo, número de documentos, documentos truncados, tempo de geração, se veio do cache e dispositivo. Esses dados vão para `result/tp2/semantic_stats.json`.

=== `evaluate_semantic` e `SemanticRun`

#funcao("def evaluate_semantic(index, queries, qrels_by_query, top_k=100) -> SemanticRun")[
  Para cada consulta, chama `search` e guarda o ranking e o tempo. Calcula as métricas por consulta e as médias. Devolve um `SemanticRun`, com a mesma forma do `LexicalRun`. Os rankings têm os 100 primeiros documentos, que é o que o RRF usa.
]

== Escolha do modelo

Foram comparados dois modelos no dev, ambos com 384 dimensões:

#tabela(
  (auto, auto, auto, auto, auto),
  [*Modelo*], [*NDCG\@10 (dev)*], [*Tamanho máximo*], [*Documentos truncados*], [*Treinado para*],
  [`all-MiniLM-L6-v2`], [*0,3024*], [256 tokens], [2.864], [similaridade geral entre frases],
  [`multi-qa-MiniLM-L6-cos-v1`], [0,2718], [512 tokens], [330], [pares pergunta–resposta],
)

Curiosamente, o modelo que lê mais texto (512 tokens, quase sem truncamento) foi o pior no dev: ler o documento inteiro não compensou a diferença entre os dois modelos. Os experimentos não isolam a causa; os modelos diferem nos dados de treinamento e no limite de tamanho ao mesmo tempo.

O `all-MiniLM-L6-v2` foi escolhido pelo maior NDCG\@10 no dev. No test, a busca semântica teve NDCG\@10 de 0,3167, um pouco acima do BM25 (0,3124).
