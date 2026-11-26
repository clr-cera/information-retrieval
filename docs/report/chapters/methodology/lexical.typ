== Busca lexical (BM25)

O baseline lexical é o *BM25* (`ProbabilisticModel`, reaproveitado do TP1), usado em todos os experimentos seguintes:

$ "score"(d, q) = sum_(t in q) "IDF"(t) dot (t f(t, d) (k_1 + 1)) / (t f(t, d) + k_1 (1 - b + b |d| \/ "avgdl")), quad "IDF"(t) = log(1 + (N - n_t + "0,5") / (n_t + "0,5")) $

A escolha se apoia em duas razões. No TP1 (Cranfield), o BM25 superou o Modelo Vetorial em MAP e na curva Precision × Recall. Na coleção dev do NFCorpus, teve NDCG\@10 de 0.2906, contra 0.2880 do TF-IDF com cosseno.

Em relação aos parâmetros, $k_1$ controla a saturação do $t f$: com $k_1 = 0$, só importa a presença do termo; valores maiores dão mais peso às repetições de termos. O parâmetro $b$ controla a normalização pelo tamanho: $b = 0$ ignora o tamanho do documento, e $b = 1$ normaliza o $t f$ completamente.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1.2fr, 1fr, 1fr, 1fr),
      align: (left, right, right, right),
      table.header([*$k_1$ \\ $b$*], [*0*], [*0,75*], [*1,0*]),
      [0,5], [0,2878], [0,2864], [0,2854],
      [1,2], [0,2899], [*0,2906*], [0,2894],
      [2,0], [_0,2916_], [0,2904], [0,2914],
    )
  },
  caption: [NDCG\@10 do BM25 no dev com variação de parâmetros.],
) <tab-bm25-grid>

Foram adotados os melhores valores indicados pelo experimento: $k_1 = "1,2"$ e $b = "0,75"$.
