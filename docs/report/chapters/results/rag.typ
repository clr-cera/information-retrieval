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

As respostas receberam notas 0, 1 ou 2 em fidelidade, completude, utilidade e rastreabilidade, cada uma com justificativa. As 20 respostas foram embaralhadas (seed 42) e avaliadas sem a indicação da condição, junto com os 5 documentos de cada consulta. A chave de cada condição só foi usada depois das notas. Na condição A, a fidelidade é julgada contra os mesmos 5 documentos, e a rastreabilidade é N/A e excluída da média.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, auto, auto),
      align: (left, right, right),
      table.header([*Critério*], [*Sem RAG (A)*], [*Com RAG (B)*]),
      [Fidelidade], [—], [—],
      [Completude], [—], [—],
      [Utilidade], [—], [—],
      [Rastreabilidade], [N/A], [—],
    )
  },
  caption: [Médias da avaliação humana (0 a 2).],
) <tab-rag-human>

// TODO (grupo): preencher as planilhas em result/tp2/rag_avaliacao/ (sem abrir a chave), rodar
// `uv run src/scripts/evaluate_rag.py merge --sheets planilha_avaliador1.csv planilha_avaliador2.csv`,
// copiar as médias e a concordância de result/tp2/rag_evaluation_summary.md para a tabela acima e discutir:
// efeito da recuperação na fidelidade e na disponibilidade de evidências; ausência de fontes na condição A.
