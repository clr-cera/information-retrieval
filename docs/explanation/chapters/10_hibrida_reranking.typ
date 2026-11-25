#import "../estilo.typ": *

= Busca híbrida e reranking (`ir/neural.py`, parte 2) <cap-hibrida>

== Busca híbrida com Reciprocal Rank Fusion

=== Teoria

A busca lexical e a semântica erram em consultas diferentes: o BM25 vai bem quando a consulta tem termos técnicos exatos (como `ergothioneine`); a busca semântica, quando há sinônimos ou paráfrases. Combinar os dois rankings tende a aproveitar o melhor de cada um.

O problema é que os scores não são comparáveis: o BM25 dá valores como 9,1 ou 15,3, sem limite superior, e o cosseno fica entre −1 e 1. Somar os dois não faz sentido, e normalizá-los depende de escolhas arbitrárias. O *Reciprocal Rank Fusion* (RRF) evita o problema usando só as *posições*:
$ "RRF"(d) = sum_(s in {"lexical", "semântico"}) 1 / (k + "rank"_s (d)) $

em que $"rank"_s (d)$ é a posição do documento $d$ no ranking do sistema $s$, começando em 1. Um documento ausente de um ranking não recebe contribuição desse sistema. A constante $k$ controla o peso do topo: com $k$ pequeno, a 1ª posição vale muito mais do que a 10ª; com $k$ grande, as posições ficam mais parecidas.

=== Exemplo calculado

Ranking lexical: d1, d2, d3. Ranking semântico: d2, d4, d1.

#tabela(
  (auto, auto, auto, auto, auto),
  [*Documento*], [*Posições*], [*RRF com $k = 60$*], [*RRF com $k = 10$*], [*Posição final*],
  [d2], [2 e 1], [$1\/62 + 1\/61 = "0,03252"$], [$1\/12 + 1\/11 = "0,17424"$], [1º],
  [d1], [1 e 3], [$1\/61 + 1\/63 = "0,03227"$], [$1\/11 + 1\/13 = "0,16783"$], [2º],
  [d4], [só semântico, 2], [$1\/62 = "0,01613"$], [$1\/12 = "0,08333"$], [3º],
  [d3], [só lexical, 3], [$1\/63 = "0,01587"$], [$1\/13 = "0,07692"$], [4º],
)

d2 fica em primeiro por estar no topo dos dois rankings; d1, que era o primeiro do BM25, cai para segundo porque o semântico o pôs em terceiro.

=== O código

#funcao("def reciprocal_rank_fusion(lexical_rankings, semantic_rankings, k, depth=100) -> dict")[
  Valida que $k > 0$ e que os dois sistemas têm as mesmas consultas. Para cada consulta, percorre os `depth` primeiros documentos de cada ranking com `enumerate(..., start=1)` e soma `1.0 / (k + rank)` no dicionário `scores`; o `scores.get(document_id, 0.0)` trata o documento que aparece pela primeira vez. Os scores originais dos sistemas são ignorados (o `_` em `for rank, (document_id, _)`). Ordena por RRF decrescente, com desempate por identificador. O ranking híbrido pode ter até 200 documentos (se os dois top-100 não tiverem nada em comum).
]

#funcao("def evaluate_rankings(rankings, qrels_by_query) -> tuple[dict, dict]")[Calcula as métricas por consulta e as médias de rankings prontos. Usado para o híbrido, que não tem uma classe de execução própria.]

=== Escolha de $k$

No dev, com os 100 primeiros de cada sistema: $k = 10$ deu NDCG\@10 de 0,3299; $k = 60$ e $k = 100$, 0,3273. O enunciado manda escolher o maior: $k = 10$. No test, o híbrido teve NDCG\@10 de 0,3440, acima do lexical (0,3124) e do semântico (0,3167).

== Reranking com cross-encoder

=== Teoria

O bi-encoder (@cap-semantica) gera os vetores da consulta e do documento separadamente; o modelo nunca vê os dois juntos. Um *cross-encoder* recebe o *par* `[CLS] consulta [SEP] documento [SEP]` como um único texto. A atenção do Transformer relaciona cada palavra da consulta com cada palavra do documento, e o modelo devolve um único número: o score de relevância do par.

#tabela(
  (auto, 1fr, 1fr),
  [], [*Bi-encoder*], [*Cross-encoder*],
  [Entrada], [consulta ou documento, sozinhos], [consulta e documento juntos],
  [Saída], [um vetor por texto], [um score por par],
  [Pode pré-calcular?], [sim (vetores dos documentos)], [não: cada par exige uma passada pelo modelo],
  [Custo por consulta], [1 passada (a consulta)], [1 passada por documento avaliado],
  [Precisão], [menor], [maior],
)

Como é caro, o cross-encoder não avalia a coleção inteira: ele só *reordena* os 50 primeiros do ranking híbrido. Os documentos abaixo da posição 50 continuam depois, na mesma ordem relativa do híbrido, para que o ranking continue completo para as métricas.

O modelo usado, `cross-encoder/ms-marco-MiniLM-L6-v2`, foi treinado no MS MARCO, um conjunto de consultas do buscador Bing com trechos de páginas relevantes. O score que ele devolve não é uma probabilidade, e sim um valor sem limite fixo: só a ordem importa.

=== O código

#funcao("RerankPredictor = Callable[[list[tuple[str, str]]], Sequence[float]]")[Apelido de tipo: "uma função que recebe uma lista de pares (consulta, documento) e devolve um score por par". Permite testar o reranking com uma função falsa, sem carregar o modelo.]

#funcao("def build_rerank_pairs(query, ranking, document_texts, depth) -> (top, tail, pairs)")[Separa o ranking em `top` (os `depth` primeiros) e `tail` (o resto) e monta os pares `(consulta, título + texto)` dos documentos do topo.]

#funcao("def rerank_from_scores(top, tail, scores) -> list")[
  Verifica que há um score por candidato. Troca o score de cada documento do topo pelo score do cross-encoder, reordena o topo por esse score (desempate por identificador) e concatena o `tail`, que fica inalterado e com os scores RRF originais.
]

#atencao(titulo: "Scores misturados no CSV")[
  No `results_reranking.csv`, a coluna `score` tem o score do cross-encoder nas posições 1 a 50 e o score RRF nas posições 51 a 100. São escalas diferentes e não devem ser comparadas entre si.
]

#funcao("def rerank_candidates(query, ranking, document_texts, predict, depth=50) -> list")[A sequência completa (montar pares, chamar `predict`, reordenar) com uma função de predição qualquer. Usada nos testes.]

#funcao("class CrossEncoderReranker(model_name, device=None, batch_size=64)")[
  Carrega o modelo com `CrossEncoder(model_name, device=...)` (importado só aqui, pelo mesmo motivo do `SentenceTransformer`). Guarda o tamanho máximo de entrada (`max_length`, 512 tokens para o par inteiro) e o tokenizador.
  - `_predict(pairs)`: `self.model.predict(pairs, batch_size=64)` processa 64 pares por vez e devolve os scores.
  - `_count_truncated_pairs(pairs)`: tokeniza os pares sem truncar e conta os que passam de 512 tokens. No test, foram 1.426 de 16.150 pares (8,8%), bem menos do que no bi-encoder, porque o limite é o dobro.
  - `rerank_query(query, ranking, document_texts, depth=50)`: faz o reranking de uma consulta e devolve o ranking, o tempo e o número de pares truncados.
]

#funcao("def evaluate_reranker(reranker, hybrid_rankings, queries, document_texts, qrels_by_query, depth=50) -> RerankerRun")[Aplica o reranking a todas as consultas, soma os pares truncados, calcula as métricas e devolve um `RerankerRun` (rankings, métricas, tempos, nome do modelo, tamanho máximo, pares truncados e dispositivo).]

=== Escolha do modelo

No dev, sobre o mesmo ranking híbrido: `ms-marco-MiniLM-L6-v2` teve NDCG\@10 de 0,3310 e levou 3,72 s por consulta; `ms-marco-TinyBERT-L2-v2` (2 camadas, menor), 0,3237 e 0,36 s. Foi escolhido o MiniLM, pelo maior NDCG\@10. No test, o reranking chegou a NDCG\@10 de 0,3557, o melhor dos quatro sistemas, ao custo de cerca de 4 s por consulta em CPU (50 passadas pelo modelo).

== Montagem do pipeline a partir da configuração

A última parte de `ir/neural.py` (vinda de `retrieval_components.py`) conecta o arquivo de configuração aos sistemas. Ela importa `PipelineOptions`, `LexicalIndex`, `LexicalRun` e `evaluate_bm25` (de `ir.lexical`) e `FUSION_DEPTH` e `NFCorpusSplit` (de `ir.data`).

#funcao("selected_lexical_config(config) / selected_semantic_model(config) / selected_rrf_k(config) / selected_reranker_model(config)")[Leem do bloco `selected` do config o valor de cada componente. Se o valor for `None` (ainda não escolhido), lançam um erro dizendo qual script de ajuste rodar primeiro.]

#funcao("def build_lexical_run(split, config) -> LexicalRun")[Constrói o índice com o pipeline do config e roda o BM25 com $k_1$ e $b$ do config em todas as consultas do split.]

#funcao("def build_semantic_run(split, config) -> SemanticRun")[Cria o `SemanticIndex` com o modelo do config (usando o cache de embeddings) e roda a busca, guardando os 100 primeiros de cada consulta.]

#funcao("def build_hybrid_rankings(lexical_run, semantic_run, rrf_k) -> dict")[Aplica o RRF aos rankings das duas execuções, com profundidade 100.]

Com essas funções, um script monta o pipeline inteiro em poucas linhas, sempre com as escolhas registradas no config.
