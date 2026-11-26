#import "../estilo.typ": *

= Busca semântica (`ir/neural.py`) <cap-semantica>

== Teoria

O BM25 só encontra documentos com os *mesmos termos* da consulta: "heart attack" não casa com "myocardial infarction". A busca semântica resolve essa *variação de vocabulário* representando cada texto por um *embedding*, um vetor produzido por uma rede neural treinada para que textos de significado parecido tenham vetores próximos.

O modelo, `sentence-transformers/all-MiniLM-L6-v2`, faz três coisas:

+ *Transformer* (MiniLM, 6 camadas): divide o texto em *subpalavras* (`ergothioneine` → `er ##go ##thi ##one ##ine`) e produz um vetor de 384 números por token. Pela *atenção*, cada vetor leva em conta os outros tokens do texto.
+ *Mean pooling*: a média dos vetores dos tokens vira um único vetor para o texto.
+ *Normalização*: o vetor passa a ter comprimento 1.

A similaridade é o *cosseno* entre os vetores. Como eles têm comprimento 1, o cosseno é igual ao produto escalar, e ranquear a coleção inteira é *uma multiplicação de matriz por vetor* (3.633 × 384 por 384), que leva milissegundos. Por isso a busca é exaustiva — o enunciado permite isso na busca semântica.

O modelo é um *bi-encoder*: consulta e documento passam pelo modelo separadamente. Os vetores dos documentos são calculados uma vez e guardados; na busca, só a consulta passa pelo modelo. O preço é que o modelo nunca vê consulta e documento juntos (o cross-encoder do @cap-hibrida faz isso).

#atencao(titulo: "Truncamento")[
  O modelo lê no máximo 256 tokens. Os documentos têm em média 357, então *78,8% deles (2.864) são cortados*, e 32% dos tokens da coleção não entram nos embeddings. Na prática, o vetor de um documento longo representa o título e o começo do resumo.
]

== O que o código faz

- `SemanticIndex` carrega o modelo (baixado do Hugging Face na primeira vez; GPU se houver, CPU neste trabalho) e obtém a matriz de embeddings dos documentos. Ela fica em *cache* em `data/embeddings/<modelo>/`, que só é reaproveitado se a lista de documentos, o modelo, a dimensão e a normalização coincidirem. Gerar a matriz leva cerca de 110 s em CPU; o índice também conta quantos documentos são truncados, usando o tokenizador do modelo.
- `search` gera o vetor da consulta e ordena os documentos pelo produto escalar (desempate pelo identificador). São cerca de 0,16 s por consulta, quase tudo para gerar o vetor.
- `evaluate_semantic` roda todas as consultas, guarda os 100 primeiros de cada uma (o que entra no RRF) e calcula as métricas, devolvendo um `SemanticRun`.

O `sentence-transformers` e o PyTorch só são importados quando um `SemanticIndex` é criado, para que scripts que não usam a busca semântica não paguem os segundos de carregamento.

== Escolha do modelo

#tabela(
  (auto, auto, auto, auto, 1fr),
  [*Modelo*], [*NDCG\@10 (dev)*], [*Limite*], [*Truncados*], [*Treinado para*],
  [`all-MiniLM-L6-v2`], [*0,3024*], [256], [2.864], [similaridade geral entre frases],
  [`multi-qa-MiniLM-L6-cos-v1`], [0,2718], [512], [330], [pares pergunta–resposta],
)

O modelo que lê o documento quase inteiro foi o pior no dev. Os experimentos não isolam a causa, porque os modelos diferem no treinamento e no limite ao mesmo tempo. Foi escolhido o `all-MiniLM-L6-v2`; no test, ele teve NDCG\@10 de 0,3167, pouco acima do BM25 (0,3124).
