#import "../estilo.typ": *

= Métricas de avaliação (`ir/metrics.py`) <cap-metricas>

Todos os sistemas produzem um ranking por consulta, e as métricas dizem o quanto ele se aproxima dos qrels. No NFCorpus, os graus são 1 ou 2; documentos sem julgamento contam como grau 0. Todas as métricas usam um *corte* $k$: $k = 10$ na avaliação e $k = 5$ no RAG. Seja $R$ o número total de relevantes da consulta.

#tabela(
  (auto, 1fr, 1fr),
  [*Métrica*], [*Definição*], [*Pergunta que responde*],
  [P\@k], [relevantes no top-$k$ ÷ $k$], [Dos documentos mostrados, quantos servem?],
  [R\@k], [relevantes no top-$k$ ÷ $R$], [Do que existia de útil, quanto foi achado?],
  [AP\@k], [$1/R sum_(i <= k) P\@i dot bb(1)["posição " i " é relevante"]$], [Os relevantes estão no topo? (MAP\@k = média sobre as consultas)],
  [NDCG\@k], [DCG\@k ÷ IDCG\@k, com $"DCG"\@k = sum_(i <= k) "grau"_i \/ log_2(i+1)$], [O ranking usa bem os *graus* e as posições?],
  [Hit\@k], [1 se há algum relevante no top-$k$], [Algum documento útil chegou à LLM? (só no RAG)],
)

Pontos que costumam confundir:

- Na *AP\@k*, relevantes fora do top-$k$ não somam nada, mas continuam no denominador $R$. É a convenção do `trec_eval`/`ir_measures`, exigida pelo enunciado.
- No *NDCG*, o desconto $log_2(i+1)$ vale 1 na posição 1, 1,58 na 2 e 2 na 3: o topo pesa mais. O IDCG é o DCG do *ranking ideal*, montado com todos os julgamentos da consulta, inclusive documentos que o sistema não recuperou. O ganho é linear (o próprio grau).
- O *R\@10* é baixo para qualquer sistema: com cerca de 38 relevantes por consulta, um top-10 perfeito ainda mostra só uma parte.

== Exemplo calculado

Qrels: `a` (grau 2), `b` e `c` (grau 1), logo $R = 3$. Ranking: `x, a, y, c, w`. Com $k = 5$:

#tabela(
  (auto, 1fr),
  [*Métrica*], [*Cálculo*],
  [P\@5], [`a` e `c` no top-5 → $2\/5 = "0,4"$],
  [R\@5], [$2\/3 approx "0,667"$],
  [AP\@5], [$(P\@2 + P\@4)\/R = (1\/2 + 2\/4)\/3 = "0,333"$],
  [NDCG\@5], [DCG $= 2\/log_2 3 + 1\/log_2 5 = "1,6925"$; IDCG (graus 2, 1, 1) $= 2 + "0,6309" + "0,5" = "3,1309"$; NDCG $= "0,5406"$],
)

== O arquivo

`ir/metrics.py` não depende de nada do projeto. Tem uma função por métrica para uma consulta (recebem a lista ordenada de `doc_id` e o dicionário `{doc_id: grau}`), `compute_metrics` (as quatro métricas com corte 10), `compute_per_query_metrics` (todas as consultas; lança erro se faltar o ranking de alguma consulta julgada, porque isso distorceria a média) e `aggregate_metrics` (média simples; a média de AP\@10 é o MAP\@10). Os nomes `P10`, `R10`, `AP10` e `NDCG10` são as colunas do `metrics_per_query.csv`.

#ideia(titulo: "Como sabemos que as métricas estão certas")[
  `validate_experiment.py` e um teste automático comparam estas funções com a biblioteca `ir_measures`, que implementa o `trec_eval`. A diferença é menor que $10^(-12)$.
]
