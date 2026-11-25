#import "../estilo.typ": *

= Métricas de avaliação (`ir/metrics.py`) <cap-metricas>

As métricas vêm primeiro porque todos os outros módulos as usam: cada sistema produz um ranking, e as métricas dizem o quanto esse ranking se aproxima dos julgamentos humanos.

== Teoria

Para uma consulta, o sistema devolve uma lista ordenada de documentos. Os qrels dizem quais documentos são relevantes e com que grau (no NFCorpus, grau 1 ou 2; documentos ausentes dos qrels contam como grau 0). Todas as métricas usam um *corte* $k$: só os $k$ primeiros documentos importam. O trabalho usa $k = 10$ (e $k = 5$ no RAG).

Seja $"rel"$ o conjunto de documentos com grau maior que zero e $R = |"rel"|$ o número total de relevantes da consulta.

=== Precision\@k

Fração dos $k$ primeiros documentos que são relevantes:
$ P\@k = (|{"documentos relevantes entre os " k " primeiros"}|) / k $

Responde: "dos documentos que mostrei, quantos servem?". Se o sistema devolve menos de $k$ documentos, as posições vazias contam como não relevantes (o denominador continua $k$).

=== Recall\@k

Fração de *todos* os relevantes da consulta que apareceram entre os $k$ primeiros:
$ R\@k = (|{"documentos relevantes entre os " k " primeiros"}|) / R $

Responde: "do que existia de útil, quanto eu achei?". No NFCorpus, as consultas têm em média cerca de 38 relevantes, então mesmo um top-10 perfeito teria $R\@10$ baixo para muitas consultas.

=== Average Precision\@k e MAP\@k

A AP\@k olha para *onde* os relevantes aparecem. Para cada posição $i <= k$ que contém um documento relevante, calcula-se $P\@i$; a AP\@k é a soma desses valores dividida pelo número total de relevantes da consulta:
$ "AP"\@k = 1/R sum_(i=1)^k P\@i dot bb(1)["o documento na posição " i " é relevante"] $

Relevantes no topo contribuem com $P\@i$ alto; relevantes mais abaixo, com valores menores; relevantes que não aparecem no top-$k$ contribuem com zero, mas continuam contando no denominador $R$. Essa é a convenção do `trec_eval` e do `ir_measures`, exigida pelo enunciado. O *MAP\@k* é a média da AP\@k sobre todas as consultas.

=== NDCG\@k

As métricas anteriores tratam relevância como sim ou não. O NDCG usa os *graus*. Cada documento na posição $i$ contribui com o seu grau (*ganho linear*), descontado pela posição:
$ "DCG"\@k = sum_(i=1)^k ("grau"_i) / (log_2(i + 1)) $

O desconto $log_2(i+1)$ vale 1 na posição 1, 1,58 na 2, 2 na 3, e cresce devagar: documentos no topo pesam mais. Para que o valor fique entre 0 e 1, divide-se pelo DCG do *ranking ideal* (IDCG), que ordena todos os julgamentos da consulta do maior grau para o menor — inclusive documentos que o sistema nem recuperou:
$ "NDCG"\@k = ("DCG"\@k) / ("IDCG"\@k) $

=== Hit\@k

Vale 1 se pelo menos um relevante está entre os $k$ primeiros, e 0 caso contrário. É usado no RAG ($k = 5$) para saber se algum documento útil chegou ao modelo de linguagem.

== Exemplo calculado

Consulta com qrels `a` (grau 2), `b` (grau 1) e `c` (grau 1), logo $R = 3$. O sistema devolve `x, a, y, c, w`. Com $k = 5$:

#tabela(
  (auto, 1fr),
  [*Métrica*], [*Cálculo*],
  [P\@5], [relevantes no top-5: `a` e `c` → $2 \/ 5 = "0,4"$],
  [R\@5], [$2 \/ 3 approx "0,667"$],
  [AP\@5], [`a` na posição 2: $P\@2 = 1\/2$; `c` na posição 4: $P\@4 = 2\/4$. Soma $= 1$; dividido por $R = 3$ → $"0,333"$],
  [DCG\@5], [$2\/log_2 3 + 1\/log_2 5 = "1,2619" + "0,4307" = "1,6925"$],
  [IDCG\@5], [ranking ideal com graus 2, 1, 1: $2\/1 + 1\/log_2 3 + 1\/log_2 4 = 2 + "0,6309" + "0,5" = "3,1309"$],
  [NDCG\@5], [$"1,6925" \/ "3,1309" = "0,5406"$],
)

Esses valores são exatamente os que as funções do módulo devolvem para essa entrada.

== O código

O módulo não importa nada do projeto. Imports:

- `math`: só para `math.log2`, o logaritmo na base 2 do NDCG.
- `Mapping` e `Sequence` (de `collections.abc`): tipos dos parâmetros.

Constantes:

- `DEFAULT_CUTOFF = 10`: o $k$ usado na avaliação.
- `METRIC_KEYS = ("P10", "R10", "AP10", "NDCG10")`: os nomes das métricas, usados como chaves de dicionário e como colunas do `metrics_per_query.csv`.

Em todas as funções, `ranked_doc_ids` é a lista de identificadores na ordem do ranking, e `qrels` é o dicionário `{doc_id: grau}` daquela consulta.

#funcao("def _relevant_doc_ids(qrels: Mapping[str, int]) -> set[str]")[
  Auxiliar interna (o `_` no início indica uso interno). Devolve o conjunto dos documentos com grau maior que zero. Um conjunto permite testar `doc_id in relevantes` em tempo constante.
]

#funcao("def precision_at_k(ranked_doc_ids, qrels, k) -> float")[
  Pega os `k` primeiros (`list(ranked_doc_ids)[:k]`), conta quantos estão no conjunto de relevantes (`sum(doc_id in relevant for doc_id in top_k)`) e divide por `k`. Se `k <= 0`, devolve 0.
]

#funcao("def recall_at_k(ranked_doc_ids, qrels, k) -> float")[
  Mesma contagem, mas divide pelo número total de relevantes. Se a consulta não tem nenhum relevante, devolve 0 (evita divisão por zero).
]

#funcao("def average_precision_at_k(ranked_doc_ids, qrels, k) -> float")[
  Percorre os `k` primeiros com `enumerate(..., start=1)`, que dá a posição a partir de 1. Mantém `hits` (relevantes vistos até agora); a cada relevante, soma `hits / rank`, que é a $P\@"rank"$ naquela posição. No fim, divide a soma por `len(relevant)`, o total de relevantes nos qrels.
]

#funcao("def ndcg_at_k(ranked_doc_ids, qrels, k) -> float")[
  - DCG: para cada posição `rank` do top-`k`, soma `max(qrels.get(doc_id, 0), 0) / math.log2(rank + 1)`. O `get(doc_id, 0)` dá grau 0 a documentos sem julgamento; o `max(..., 0)` protege contra graus negativos.
  - IDCG: ordena os graus positivos de todos os julgamentos do maior para o menor (`sorted(..., reverse=True)`), pega os `k` primeiros e aplica a mesma soma.
  - Devolve `dcg / idcg`, ou 0 se não houver relevantes (`idcg == 0`).
]

#funcao("def hit_at_k(ranked_doc_ids, qrels, k) -> float")[
  `any(...)` devolve `True` assim que encontra um relevante entre os `k` primeiros; a função converte para 1,0 ou 0,0.
]

#funcao("def compute_metrics(ranked_doc_ids, qrels) -> dict[str, float]")[
  Calcula as quatro métricas com corte 10 para uma consulta e devolve `{"P10": ..., "R10": ..., "AP10": ..., "NDCG10": ...}`.
]

#funcao("def compute_per_query_metrics(rankings, qrels_by_query) -> dict[str, dict[str, float]]")[
  Recebe os rankings de todas as consultas e os qrels de todas as consultas. Primeiro verifica se toda consulta julgada tem ranking (`set(qrels_by_query) - set(rankings)`); se faltar alguma, lança `ValueError`, porque uma consulta ausente distorceria a média. Depois chama `compute_metrics` para cada consulta. O resultado é o que vai para o `metrics_per_query.csv`.
]

#funcao("def aggregate_metrics(per_query_metrics) -> dict[str, float]")[
  Média simples de cada métrica sobre as consultas. A média de `AP10` é o MAP\@10. Sem consultas, devolve zeros.
]

#ideia(titulo: "Como sabemos que as métricas estão certas")[
  O script `validate_experiment.py` e o teste `test_matches_ir_measures_on_random_cases` comparam estas funções com a biblioteca `ir_measures`, que implementa as métricas oficiais do `trec_eval`. A diferença é menor que $10^(-12)$.
]
