== RAG

=== Recuperação do contexto

A @tab-rag-retrieval mostra a qualidade dos 5 documentos enviados à LLM e a melhor posição de um relevante em cada estágio (`evaluate_rag.py`).

#figure(
  {
    set par(justify: false)
    set text(size: 8pt)
    table(
      columns: (auto, 2.4fr, auto, auto, auto, auto, auto, auto, auto, auto),
      inset: (x: 4pt, y: 4pt),
      align: (left, left, right, right, right, right, right, right, right, right),
      table.header([*Consulta*], [*Pergunta*], [*Rel.*], [*Lex.*], [*Sem.*], [*Híb.*], [*Rer.*], [*P\@5*], [*R\@5*], [*Hit\@5*]),
      [PLAIN-68], [What is Actually in Chicken Nuggets?], [55], [1], [1], [1], [1], [0,2], [0,018], [1],
      [PLAIN-2450], [Are Organic Foods Safer?], [38], [2], [3], [4], [2], [0,4], [0,053], [1],
      [PLAIN-153], [How Should I Take Probiotics?], [47], [1], [1], [1], [1], [1,0], [0,106], [1],
      [PLAIN-2850], [More Antibiotics In White Meat or Dark Meat?], [9], [14], [14], [11], [11], [0,0], [0,000], [*0*],
      [PLAIN-2750], [Preventing the Common Cold with Probiotics?], [59], [1], [1], [1], [1], [0,8], [0,068], [1],
      [PLAIN-270], [Is Caffeinated Tea Really Dehydrating?], [52], [4], [1], [2], [1], [0,2], [0,019], [1],
      [PLAIN-2470], [Is Milk Good for Our Bones?], [73], [2], [1], [1], [1], [0,6], [0,041], [1],
      [PLAIN-2430], [Preventing Brain Loss with B Vitamins?], [46], [1], [1], [1], [1], [0,6], [0,065], [1],
      [PLAIN-238], [How Chemically Contaminated Are We?], [54], [10], [24], [11], [2], [0,2], [0,019], [1],
      [PLAIN-3342], [Is Coconut Milk Good For You?], [3], [1], [2], [1], [1], [0,4], [0,667], [1],
      table.cell(colspan: 7)[*Média*], [*0,44*], [*0,106*], [*0,90*],
    )
  },
  caption: [Recuperação para o RAG. "Rel.": relevantes nos qrels; "Lex.", "Sem.", "Híb." e "Rer.": melhor posição de um relevante no lexical, semântico, híbrido e após o reranking.],
) <tab-rag-retrieval>

Em 9 das 10 consultas, ao menos um relevante chegou ao contexto (Hit\@5 = 0,9), e em média 2,2 dos 5 documentos enviados são relevantes. O R\@5 baixo (0,106) é esperado, porque as consultas têm em média cerca de 44 relevantes. Na PLAIN-238, o reranking foi decisivo, levando o melhor relevante de 11º para 2º. A exceção é a PLAIN-2850, discutida na análise de falhas.

=== Geração

As respostas das duas condições têm tamanhos parecidos (123 e 124 palavras em média).

- *Condição B:* todas as respostas citam de 1 a 4 documentos, e todos estão entre os enviados (nenhuma fonte inventada). Duas delas (PLAIN-2850 e PLAIN-3342) declaram que falta evidência para parte da pergunta.
- *Condição A:* nenhuma resposta indica fontes, o que impede verificar as afirmações.

Para apoiar a avaliação, as afirmações principais de cada resposta foram comparadas com os 5 documentos da consulta, numa ficha de evidências sem notas e sem a condição (`result/tp2/rag_avaliacao/ficha_evidencias.md`, elaborada com apoio de IA e conferida pelo grupo). A comparação mostra duas diferenças claras entre as condições:

- *Sem RAG, três respostas contradizem os documentos em afirmações centrais.* Na PLAIN-2750, a LLM diz que a maioria dos estudos não mostra redução de resfriados com probióticos, contra três documentos que mostram essa redução. Na PLAIN-2470, diz que o leite faz bem aos ossos, mas os três estudos sobre leite e fraturas enviados (MED-1337, MED-1340 e MED-1338) não encontram menos fraturas com mais leite. Na PLAIN-68, descreve nuggets feitos principalmente de frango, enquanto o MED-2991 mostra que a carne não é o componente predominante. Nas demais, há conselhos genéricos sem apoio no contexto, números não verificáveis e, na PLAIN-238, uma fonte externa ("a OMS") que não pode ser conferida. Na PLAIN-270 e na PLAIN-2450, a conclusão sem RAG coincide com a dos documentos.
- *Com RAG, as afirmações principais podem ser associadas aos documentos citados, mas há imprecisões e omissões pontuais.* A resposta da PLAIN-2850 trata carne bovina como "dark meat"; a da PLAIN-2750 diz que a gravidade do resfriado caiu de forma significativa, quando só os sintomas faríngeos tiveram redução significativa; e a da PLAIN-2430 junta numa frase dois resultados distintos do MED-994. Documentos relevantes do contexto às vezes ficam de fora: o MED-1338 (mais fraturas em mulheres com consumo alto de leite) e a revisão Cochrane MED-3680 (probióticos e infecções respiratórias) não são usados.

Cada resposta recebeu notas 0, 1 ou 2 em fidelidade, completude, utilidade e rastreabilidade, cada uma com justificativa. As 20 respostas foram embaralhadas (seed 42) e apresentadas sem a condição, junto com os 5 documentos de cada consulta. Na condição A, a fidelidade é julgada contra os mesmos 5 documentos, e a rastreabilidade é N/A e excluída da média. A avaliação *humana* foi feita por uma integrante do grupo (Clara Ernesto de Carvalho), sem a chave das condições; as notas finais, gravadas no `rag_experiment.csv`, são as dela. Uma segunda avaliação, com os mesmos critérios, foi feita por um *LLM* (Claude, pelo Claude Code). Ela não foi cega, porque o modelo conhecia as condições e havia elaborado a ficha de evidências, e serve só para medir a concordância.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, auto, auto, auto, auto, auto),
      align: (left, right, right, right, right, right),
      table.header(table.cell(rowspan: 2)[*Critério*], table.cell(colspan: 2)[*Humana*], table.cell(colspan: 2)[*LLM*], table.cell(rowspan: 2)[*Concordância exata*],
        [*Sem RAG (A)*], [*Com RAG (B)*], [*A*], [*B*]),
      [Fidelidade], [0,60], [2,00], [0,50], [1,90], [90% (20 pares)],
      [Completude], [1,70], [1,90], [1,10], [1,70], [60% (20 pares)],
      [Utilidade], [1,80], [1,80], [1,10], [1,70], [60% (20 pares)],
      [Rastreabilidade], [N/A], [2,00], [N/A], [2,00], [100% (10 pares)],
    )
  },
  caption: [Médias das notas (0 a 2) por condição e concordância entre a avaliação humana e a do LLM.],
) <tab-rag-human>

*Fidelidade é onde o RAG faz diferença* (0,60 → 2,00 na avaliação humana). Sem RAG, nenhuma resposta teve nota 2: quatro tiveram 0 (PLAIN-68, PLAIN-2850, PLAIN-2750 e PLAIN-3342), e as demais tiveram 1, por misturar conclusões compatíveis com os documentos e detalhes sem apoio. Com RAG, todas as respostas tiveram nota 2, e a rastreabilidade também foi máxima, o que confirma a comparação das afirmações acima. Na condição A, a falta de fontes significa que quem lê não tem como separar o que é correto do que é inventado: as respostas soam igualmente seguras nos dois casos.

*Completude e utilidade quase não mudam* (1,70 → 1,90 e 1,80 → 1,80). As respostas sem RAG são diretas e cobrem o assunto, ainda que sem base, e por isso foram vistas como úteis. Com RAG, a utilidade cai justamente quando a LLM declara que o contexto não basta (PLAIN-2850 e PLAIN-3342, nota 1): a resposta fica mais honesta, mas não responde à pergunta. O ganho do RAG neste experimento está na *verificabilidade*, e não em respostas mais completas.

*Concordância.* A fidelidade teve 90% de notas iguais, e a rastreabilidade, 100%. Completude e utilidade tiveram 60%. Todas as 18 discordâncias têm a mesma direção: o LLM deu a nota mais baixa. Em 14 delas, a resposta era da condição A: o LLM penalizou a completude e a utilidade de respostas sem sustentação, enquanto a avaliação humana julgou esses critérios de forma independente da fidelidade. Essa diferença de interpretação aparece também nas médias do LLM, que veem um ganho do RAG em todos os critérios. A concordância deve ser lida com uma ressalva: a ficha de evidências, disponível à avaliadora, foi elaborada pelo mesmo modelo que fez a segunda avaliação, o que tende a aproximar as notas.
