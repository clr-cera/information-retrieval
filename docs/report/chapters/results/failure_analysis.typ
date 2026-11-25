== Análise de falhas ponta a ponta

// TODO (grupo): após a avaliação humana, escolher entre as 10 consultas (a) uma em que o RAG melhorou claramente a
// resposta e (b) uma com pouca diferença, pelas notas de result/tp2/rag_evaluation_summary.md e rag_experiment.csv,
// e analisá-las como o caso abaixo (documentos enviados, o que a resposta usou, notas e justificativas).

*RAG não ajudou — PLAIN-2850, "More Antibiotics In White Meat or Dark Meat?"* Esta é a única consulta em que nenhum documento relevante chegou ao contexto (Hit\@5 = 0). Seguindo a consulta por todos os estágios, foi possível localizar onde a informação se perdeu.

A coleção tem a resposta: o documento MED-4166 (grau 2), "Concentrations of antibiotic residues vary between different edible muscle tissues in poultry", compara frangos tratados com enrofloxacina e conclui que a concentração do antibiótico é *maior no músculo do peito do que no da coxa*, isto é, maior na carne branca. Mas o documento nunca usa as palavras "white", "dark" ou "meat": fala em "breast versus thigh muscle". Dos quatro termos da consulta (`antibiot`, `white`, `meat`, `dark`), só `antibiot` aparece nele.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1.4fr, auto, auto, auto, auto, auto),
      align: (left, right, right, right, right, right),
      table.header([*Documento*], [*Lexical*], [*Semântico*], [*Híbrido*], [*Reranking*], [*No contexto?*]),
      [MED-4166 (grau 2)], [29], [14], [11], [19], [não],
    )
  },
  caption: [Posição do documento que responde à PLAIN-2850 em cada estágio.],
) <tab-failure>

- *Recuperação lexical:* só um dos quatro termos casa (`antibiot`, presente em 56 documentos), enquanto outros documentos casam com `meat` (316 documentos), `white` (110) e `dark` (27); o documento fica em 29º.
- *Recuperação semântica:* o bi-encoder o coloca mais acima que o BM25 (14º), mas ainda longe do contexto.
- *Fusão:* o RRF combina as duas posições e o leva a 11º, o mais perto que ele chega do contexto.
- *Reranking:* o cross-encoder o rebaixa para 19º (score −8,25). Todos os 50 candidatos recebem scores negativos (o 1º tem −4,93): nenhum parece ao modelo uma boa resposta, e ele não liga "white meat or dark meat" a "breast versus thigh". Os 5 documentos escolhidos tratam de resistência bacteriana em carnes, bacteriófagos e consumo de carne e câncer.
- *Seleção de contexto:* com o corte em 5 documentos, o documento não é enviado.
- *Geração:* a LLM se comportou corretamente. A resposta com RAG afirma que os documentos não têm dados sobre resíduos de antibióticos em carne branca ou escura, distinguindo resistência bacteriana (do MED-3891, citado) de resíduos no alimento. A resposta sem RAG, ao contrário, afirma com segurança que "a cor da carne não determina os níveis de antibiótico", o que é *contradito* pelo MED-4166.

Portanto, a falha *não* está na geração, mas na recuperação: a informação necessária existia na coleção, mas não chegou ao contexto. A causa principal é uma paráfrase que exige conhecimento de mundo ("carne branca" = peito; "carne escura" = coxa), que nenhum estágio resolveu bem; o reranking, em vez de corrigir, piorou a posição do documento. O caso também mostra um benefício do RAG mesmo sem acerto: com o prompt pedindo para declarar falta de evidência, a resposta deixou de afirmar algo incorreto.
