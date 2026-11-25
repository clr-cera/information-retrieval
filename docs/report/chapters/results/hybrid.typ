== Busca híbrida

A @tab-hybrid-test compara os três sistemas no conjunto test, com o $k = 10$ escolhido no dev.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      table.header([*Sistema*], [*P\@10*], [*R\@10*], [*MAP\@10*], [*NDCG\@10*]),
      [Lexical (BM25)], [0,2307], [0,1411], [0,1109], [0,3124],
      [Semântico (bi-encoder)], [0,2433], [0,1550], [0,1108], [0,3167],
      [*Híbrido (RRF, $k = 10$)*], [*0,2557*], [*0,1657*], [*0,1259*], [*0,3440*],
    )
  },
  caption: [Lexical, semântico e híbrido no conjunto test (323 consultas).],
) <tab-hybrid-test>

O híbrido é melhor que os dois sistemas em todas as métricas: o NDCG\@10 sobe 0,0316 em relação ao lexical (+10,1%) e 0,0273 em relação ao semântico (+8,6%), e o MAP\@10 sobe cerca de 13% em relação a ambos. O custo da fusão é desprezível: 0,07 ms por consulta, contra cerca de 1 ms do BM25 e 0,16 s do bi-encoder.

O ganho vem da *complementaridade* entre os sistemas, já observada na análise por consulta:

- *Os rankings são muito diferentes.* Em média, só 22 dos 100 primeiros documentos de cada sistema são comuns aos dois, e a lista fundida tem 145 documentos.
- *Cada sistema encontra relevantes que o outro não encontra.* Entre os 100 primeiros, o lexical traz em média 6,5 documentos relevantes, e o semântico, 8,0; a união dos dois traz 9,7.
- *O RRF favorece o consenso.* Um documento presente nos dois rankings soma duas contribuições. Em média, 6,5 dos 10 primeiros documentos do híbrido estão entre os 100 primeiros dos dois sistemas; os demais vêm só do semântico (2,6) ou só do lexical (0,9).

Por consulta, o NDCG\@10 do híbrido é maior que o dos dois sistemas em 42 consultas, fica entre os dois (ou igual a um deles) em 272 e é menor que ambos em apenas 9. O número de consultas sem nenhum relevante no top-10 cai de 102 (lexical) e 100 (semântico) para 89. A fusão, porém, não alcança o melhor sistema de cada consulta: se fosse possível escolher, para cada consulta, o melhor entre lexical e semântico, o NDCG\@10 médio seria 0,3795, contra 0,3440 do híbrido. Na maioria das consultas, o RRF fica entre os dois, sem identificar qual sistema está certo.

O RRF também gera empates: um documento que só aparece na posição $r$ do lexical tem o mesmo score que outro que só aparece na posição $r$ do semântico. Em 30 das 323 consultas há empate entre a 10ª e a 11ª posição; esses casos são resolvidos pelo identificador do documento.
