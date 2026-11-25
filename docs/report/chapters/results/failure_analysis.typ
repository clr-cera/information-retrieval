== Análise de falhas ponta a ponta

// TODO (grupo): após a avaliação humana, escolher entre as 10 consultas (a) uma em que o RAG melhorou claramente a
// resposta e (b) uma com pouca diferença, pelas notas de result/tp2/rag_evaluation_summary.md e rag_experiment.csv,
// e analisá-las como o caso abaixo (documentos enviados, o que a resposta usou, notas e justificativas).

*RAG não ajudou — PLAIN-2850, "More Antibiotics In White Meat or Dark Meat?"* É a única consulta sem nenhum relevante no contexto (Hit\@5 = 0). A coleção tem a resposta: o MED-4166 (grau 2), "Concentrations of antibiotic residues vary between different edible muscle tissues in poultry", mostra que a enrofloxacina se concentra mais no músculo do peito do que no da coxa de frangos, isto é, na carne branca. Mas o documento fala em "breast versus thigh muscle" e nunca usa "white", "dark" ou "meat". Seguindo-o pelos estágios:

- *Lexical (29º):* dos quatro termos da consulta, só `antibiot` (56 documentos) aparece nele, enquanto outros documentos casam com `meat` (316), `white` (110) e `dark` (27).
- *Semântico (14º) e fusão (11º):* o bi-encoder o coloca mais acima, e o RRF o leva à posição mais próxima do contexto.
- *Reranking (19º):* o cross-encoder o rebaixa (score −8,25). Todos os 50 candidatos têm scores negativos (o 1º tem −4,93), e o modelo não liga "white meat or dark meat" a "breast versus thigh". Os 5 escolhidos tratam de resistência bacteriana em carnes, bacteriófagos e consumo de carne e câncer.
- *Seleção de contexto:* com o corte em 5, o documento não é enviado.
- *Geração:* a LLM agiu corretamente. A resposta com RAG diz que os documentos não trazem dados sobre resíduos de antibióticos em carne branca ou escura e distingue esses resíduos da resistência bacteriana, citando o MED-3891. A resposta sem RAG afirma com segurança que "a cor da carne não determina os níveis de antibiótico", o que o MED-4166 *contradiz*.

A falha está, portanto, na recuperação. A paráfrase exige conhecimento de mundo (carne branca = peito; carne escura = coxa), que nenhum estágio resolveu, e o reranking ainda piorou a posição do documento. Mesmo assim, o RAG trouxe um benefício: instruída a declarar falta de evidência, a LLM deixou de afirmar algo incorreto.
