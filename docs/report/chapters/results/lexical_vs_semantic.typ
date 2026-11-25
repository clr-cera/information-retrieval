== Busca lexical × busca semântica

=== Resultados globais

Os dois sistemas foram avaliados sobre as mesmas 323 consultas do conjunto test.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      table.header([*Sistema*], [*P\@10*], [*R\@10*], [*MAP\@10*], [*NDCG\@10*]),
      [Lexical (BM25)], [0,2307], [0,1411], [*0,1109*], [0,3124],
      [Semântico (bi-encoder)], [*0,2433*], [*0,1550*], [0,1108], [*0,3167*],
    )
  },
  caption: [Médias no conjunto test (323 consultas). Em negrito, o melhor valor de cada métrica.],
) <tab-lex-sem>

Nas médias, os dois sistemas são muito próximos. O semântico tem P\@10, R\@10 e NDCG\@10 um pouco maiores, e o MAP\@10 é praticamente igual (0,1109 contra 0,1108). Os valores de R\@10 são baixos para ambos porque as consultas têm, em média, 38 documentos relevantes, e um top-10 só pode mostrar parte deles.

As médias escondem diferenças grandes por consulta. Comparando o NDCG\@10 consulta a consulta, o semântico é melhor em 109 consultas, o lexical em 106, e os dois empatam em 108. Desses empates, 77 são consultas em que *nenhum* dos dois sistemas coloca um documento relevante no top-10. No total, o NDCG\@10 é zero em 102 consultas no lexical e em 100 no semântico, cerca de 31% das consultas em cada sistema. Como cada sistema acerta consultas diferentes, combinar os dois rankings tende a melhorar o resultado, o que motiva a busca híbrida.

=== Análise por consulta

#text(fill: gray, style: "italic")[Seção em elaboração.]

// TODO (requisito 7): as 3 consultas com maior vantagem do semântico e as 3 com maior vantagem do lexical (diferença de NDCG@10),
// com texto, top-5 de cada método, relevantes, scores e análise (correspondência lexical, termos técnicos, sinonímia,
// paráfrase, variação de vocabulário, ambiguidade). Considerar o truncamento de 78,8% dos documentos no bi-encoder.
