== Tolerância a erros

A @tab-typo-results mostra as 10 consultas do experimento. Os quatro tipos de erro foram usados: três inserções, três remoções, duas substituições e duas trocas de ordem. Todos os erros ficaram a uma ou duas edições do termo original.

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

Em média, o NDCG\@10 caiu de 0,4706 na consulta original para 0,1625 com o erro e voltou a 0,4706 após a correção. O corretor recuperou exatamente o termo original nas 10 consultas, e nenhum outro termo foi alterado. Assim, nas 8 consultas em que o erro reduziu o desempenho, a recuperação foi de 100%.

=== Impacto do erro

Em 7 das 10 consultas, o erro derrubou o NDCG\@10 para zero. Isso acontece porque as consultas do NFCorpus são muito curtas e o erro atinge o termo mais específico:

- Em quatro consultas de um único termo (`ECMO`, `ergothioneine`, `fenugreek` e `Finland`), o termo com erro não está no vocabulário, e a consulta fica sem nenhum termo: nenhum documento é recuperado.
- Em `domoic acid` e `Evidence-based medicine`, sobra apenas um termo genérico (`acid`, `medicin`), que não basta para trazer documentos relevantes ao top-10.
- Em `Stopping Heart Disease in Childhood`, a perda de `childhood` deixa apenas termos mais gerais (`stop`, `heart`, `diseas`). A consulta original já tinha só 1 documento relevante no top-10, e com o erro passa a ter nenhum.

Em `Food Dyes and ADHD`, a queda foi pequena (de 0,4027 para 0,3703): mesmo sem `food`, os termos restantes (`dye` e `adhd`) continuam trazendo documentos relevantes ao topo.

=== Casos em que o erro melhorou o resultado

Em duas consultas, ambas com troca de ordem de caracteres, a consulta com erro teve NDCG\@10 *maior* que a original. Nos dois casos, o termo com erro simplesmente deixa de existir na busca, e o resultado mostra que esse termo prejudicava o ranking lexical:

- *`factory farming practices` (0,4263 → 0,6379).* O radical `practic` aparece em 183 documentos, muito mais do que `factori` (22) e `farm` (48), e só 13 desses 183 documentos são relevantes para a consulta. Assim, o termo soma pontos sobretudo a documentos não relevantes: com ele, o top-5 tem 1 documento relevante e o top-10 tem 5; sem ele, a busca se concentra em `factory farming`, e o top-5 passa a ter 4 relevantes e o top-10, 7.
- *`endocrine disruptors` (0,4690 → 0,6168).* Aqui o termo é raro: `disruptor` aparece em apenas 13 documentos e, por isso, tem IDF alto e domina o score dos documentos que o contêm. Mas só 4 desses 13 documentos são relevantes, de um total de 98 relevantes nos qrels. Sem esse termo, o ranking passa a depender de `endocrin` (41 documentos, 12 deles relevantes), e o top-10 passa de 3 para 5 documentos relevantes.

Nesses casos, a correção devolveu a consulta original e, com ela, o NDCG\@10 original. Isso é o comportamento correto do corretor: ele restaura o que o usuário quis digitar. Os dois casos mostram, porém, uma limitação do modelo lexical, que não tem como saber quais termos de uma consulta curta são mais úteis para encontrar os documentos relevantes.
