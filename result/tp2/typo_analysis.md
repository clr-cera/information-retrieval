# Experimento de tolerância a erros

Dicionário da correção: 36477 termos (tokenização e minúsculas, antes do stemming).

## Verificação das regras do enunciado

- Todas as consultas têm NDCG@10 original maior que zero.
- Cada consulta tem exatamente um termo alterado, e o termo com erro não existe no dicionário.
- O termo original de cada consulta está no dicionário (termos antes do stemming).

## Consultas do experimento

| Consulta | Texto original | Erro | Tipo | NDCG@10 original | com erro | corrigida | Recuperação |
|---|---|---|---|---|---|---|---|
| PLAIN-102 | Stopping Heart Disease in Childhood | childhood → childhnood | insercao | 0,1253 | 0,0000 | 0,1253 | 1,0000 |
| PLAIN-1039 | domoic acid | domoic → omoic | remocao | 1,0000 | 0,0000 | 1,0000 | 1,0000 |
| PLAIN-1088 | ECMO | ecmo → ecco | substituicao | 0,5531 | 0,0000 | 0,5531 | 1,0000 |
| PLAIN-1109 | endocrine disruptors | disruptors → disrputors | transposicao | 0,4690 | 0,6168 | 0,4690 | erro não reduziu o NDCG@10 |
| PLAIN-112 | Food Dyes and ADHD | food → foodo | insercao | 0,4027 | 0,3703 | 0,4027 | 1,0000 |
| PLAIN-1130 | ergothioneine | ergothioneine → ergotioneine | remocao | 1,0000 | 0,0000 | 1,0000 | 1,0000 |
| PLAIN-1141 | Evidence-based medicine | evidencebased → evidencebasgd | substituicao | 0,2201 | 0,0000 | 0,2201 | 1,0000 |
| PLAIN-1151 | factory farming practices | practices → parctices | transposicao | 0,4263 | 0,6379 | 0,4263 | erro não reduziu o NDCG@10 |
| PLAIN-1172 | fenugreek | fenugreek → fenugbreek | insercao | 0,2201 | 0,0000 | 0,2201 | 1,0000 |
| PLAIN-1183 | Finland | finland → filand | remocao | 0,2895 | 0,0000 | 0,2895 | 1,0000 |

## Resumo

- Consultas: 10
- NDCG@10 médio: original 0,4706, com erro 0,1625, corrigida 0,4706
- Correções que voltaram exatamente à consulta original: 10 de 10
- Consultas em que o erro reduziu o NDCG@10: 8 de 10
- Recuperação média nessas consultas: 1,0000

## Tipos de erro

- insercao: 3
- remocao: 3
- substituicao: 2
- transposicao: 2
- Distância de edição entre o termo original e o termo com erro: mínima 1, máxima 2

## Consultas em que o erro não reduziu o NDCG@10

### PLAIN-1109: "endocrine disruptors" (98 documentos relevantes nos qrels)

Termos da consulta original no índice (após o pré-processamento):

- `endocrin`: presente em 41 documentos
- `disruptor`: presente em 13 documentos

Top-5 da consulta original (`endocrine disruptors`):

| Posição | Documento | Score BM25 | Grau de relevância |
|---|---|---|---|
| 1 | MED-2650 | 16,9778 | 1 |
| 2 | MED-2643 | 15,3132 | 1 |
| 3 | MED-1763 | 14,2040 | 1 |
| 4 | MED-1777 | 11,0602 | 0 |
| 5 | MED-5323 | 10,5992 | 0 |

Top-5 da consulta com erro (`endocrine disrputors`):

| Posição | Documento | Score BM25 | Grau de relevância |
|---|---|---|---|
| 1 | MED-1099 | 8,5949 | 1 |
| 2 | MED-2650 | 8,3286 | 1 |
| 3 | MED-2643 | 7,2692 | 1 |
| 4 | MED-2087 | 7,0737 | 0 |
| 5 | MED-919 | 7,0475 | 0 |

### PLAIN-1151: "factory farming practices" (153 documentos relevantes nos qrels)

Termos da consulta original no índice (após o pré-processamento):

- `factori`: presente em 22 documentos
- `farm`: presente em 48 documentos
- `practic`: presente em 183 documentos

Top-5 da consulta original (`factory farming practices`):

| Posição | Documento | Score BM25 | Grau de relevância |
|---|---|---|---|
| 1 | MED-1179 | 10,0957 | 0 |
| 2 | MED-4139 | 9,5174 | 1 |
| 3 | MED-4489 | 9,2906 | 0 |
| 4 | MED-3306 | 8,6584 | 0 |
| 5 | MED-3087 | 8,5599 | 0 |

Top-5 da consulta com erro (`factory farming parctices`):

| Posição | Documento | Score BM25 | Grau de relevância |
|---|---|---|---|
| 1 | MED-3306 | 8,6584 | 0 |
| 2 | MED-4140 | 8,2879 | 1 |
| 3 | MED-4129 | 8,2838 | 1 |
| 4 | MED-4141 | 8,1054 | 1 |
| 5 | MED-730 | 8,0444 | 1 |

