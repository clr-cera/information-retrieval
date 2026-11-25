== Tolerância a erros

#figure(
  {
    set par(justify: false)
    set text(size: 8pt)
    table(
      columns: (auto, 2.3fr, 2.6fr, auto, auto, auto, auto, auto),
      inset: (x: 4pt, y: 5pt),
      align: (left, left, left, left, right, right, right, right),
      table.header([*Consulta*], [*Texto original*], [*Erro*], [*Tipo*], [*Orig.*], [*Erro*], [*Corr.*], [*Recup.*]),
      [PLAIN-102], [Stopping Heart Disease in Childhood], [childhood → childhnood], [inserção], [0,1253], [0,0000], [0,1253], [1,00],
      [PLAIN-1039], [domoic acid], [domoic → omoic], [remoção], [1,0000], [0,0000], [1,0000], [1,00],
      [PLAIN-1088], [ECMO], [ecmo → ecco], [substituição], [0,5531], [0,0000], [0,5531], [1,00],
      [PLAIN-1109], [endocrine disruptors], [disruptors → disrputors], [troca], [0,4690], [0,6168], [0,4690], [—],
      [PLAIN-112], [Food Dyes and ADHD], [food → foodo], [inserção], [0,4027], [0,3703], [0,4027], [1,00],
      [PLAIN-1130], [ergothioneine], [ergothioneine → ergotioneine], [remoção], [1,0000], [0,0000], [1,0000], [1,00],
      [PLAIN-1141], [Evidence-based medicine], [evidencebased → evidencebasgd], [substituição], [0,2201], [0,0000], [0,2201], [1,00],
      [PLAIN-1151], [factory farming practices], [practices → parctices], [troca], [0,4263], [0,6379], [0,4263], [—],
      [PLAIN-1172], [fenugreek], [fenugreek → fenugbreek], [inserção], [0,2201], [0,0000], [0,2201], [1,00],
      [PLAIN-1183], [Finland], [finland → filand], [remoção], [0,2895], [0,0000], [0,2895], [1,00],
    )
  },
  caption: [NDCG\@10 do sistema lexical para a consulta original, com erro e corrigida, e a recuperação. "—" indica que o erro não reduziu o NDCG\@10.],
) <tab-typo-results>

Foram usados os quatro tipos de erro (3 inserções, 3 remoções, 2 substituições e 2 trocas), todos a uma ou duas edições do termo original. O NDCG\@10 médio caiu de 0,4706 para 0,1625 com o erro e voltou a 0,4706 após a correção. O corretor recuperou o termo original nas 10 consultas, sem alterar outros termos, e a recuperação foi de 100% nas 8 consultas em que o erro reduziu o desempenho.

*Impacto do erro.* Em 7 consultas, o NDCG\@10 caiu a zero, porque as consultas são curtas e o erro atinge o termo mais específico:

- nas quatro consultas de um único termo (ECMO, ergothioneine, fenugreek e Finland), a consulta fica sem nenhum termo do vocabulário, e nada é recuperado;
- em `domoic acid` e `Evidence-based medicine`, sobra só um termo genérico (`acid`, `medicin`);
- em `Stopping Heart Disease in Childhood`, restam termos gerais, e o único relevante do top-10 sai.

Em `Food Dyes and ADHD`, a queda foi pequena (0,4027 → 0,3703), porque `dye` e `adhd` continuam trazendo relevantes.

*Erros que melhoraram o resultado.* Nas duas trocas de ordem, a consulta com erro foi *melhor* que a original, porque o termo que deixou de existir prejudicava o ranking:

- *`factory farming practices`:* `practic` aparece em 183 documentos, só 13 deles relevantes. Sem esse termo, o top-10 passa de 5 para 7 relevantes.
- *`endocrine disruptors`:* `disruptor` é raro (13 documentos) e, com IDF alto, domina o score, mas só 4 desses documentos são relevantes. Sem ele, o top-10 passa de 3 para 5 relevantes.

A correção restaurou corretamente a consulta digitada. Esses casos mostram uma limitação do BM25, que não sabe quais termos de uma consulta curta ajudam a encontrar os relevantes.
