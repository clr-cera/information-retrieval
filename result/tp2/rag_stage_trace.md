# Rastreamento por estágio (consultas do RAG)

Melhor posição de um documento relevante em cada estágio (>100: nenhum entre os 100 primeiros).

| Consulta | Pergunta | Relevantes | Lexical | Semântico | Híbrido | Reranking | Relevantes no top-5 |
|---|---|---|---|---|---|---|---|
| PLAIN-68 | What is Actually in Chicken Nuggets? | 55 | 1 | 1 | 1 | 1 | MED-2991 (2) |
| PLAIN-2450 | Are Organic Foods Safer? | 38 | 2 | 3 | 4 | 2 | MED-1178 (2), MED-1173 (2) |
| PLAIN-153 | How Should I Take Probiotics? | 47 | 1 | 1 | 1 | 1 | MED-3679 (2), MED-3692 (1), MED-3695 (1), MED-3693 (1), MED-3680 (1) |
| PLAIN-2850 | More Antibiotics In White Meat or Dark Meat? | 9 | 14 | 14 | 11 | 11 | nenhum |
| PLAIN-2750 | Preventing the Common Cold with Probiotics? | 59 | 1 | 1 | 1 | 1 | MED-3683 (2), MED-3695 (1), MED-3680 (2), MED-3690 (1) |
| PLAIN-270 | Is Caffeinated Tea Really Dehydrating? | 52 | 4 | 1 | 2 | 1 | MED-4331 (1) |
| PLAIN-2470 | Is Milk Good for Our Bones? | 73 | 2 | 1 | 1 | 1 | MED-1337 (2), MED-1340 (2), MED-1338 (2) |
| PLAIN-2430 | Preventing Brain Loss with B Vitamins? | 46 | 1 | 1 | 1 | 1 | MED-994 (2), MED-980 (2), MED-986 (2) |
| PLAIN-238 | How Chemically Contaminated Are We? | 54 | 10 | 24 | 11 | 2 | MED-4739 (1) |
| PLAIN-3342 | Is Coconut Milk Good For You? | 3 | 1 | 2 | 1 | 1 | MED-5014 (2), MED-5012 (2) |
