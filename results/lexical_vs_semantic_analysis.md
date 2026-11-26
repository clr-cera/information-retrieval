# Lexical × semântico: análise por consulta

Consultas do split test: 323. Bi-encoder: `sentence-transformers/all-MiniLM-L6-v2` (máximo de 256 tokens).

# Maior vantagem do sistema semântico

## PLAIN-307: "Vitamin D: Shedding some light on the new recommendations"

- NDCG@10: lexical 0,0000, semântico 0,8194, diferença (semântico − lexical) 0,8194
- Documentos relevantes nos qrels: 3; com pelo menos um termo da consulta: 3
- Termos da consulta no índice: `vitamin` (216 docs), `shed` (13 docs), `light` (81 docs), `new` (310 docs), `recommend` (272 docs)

### Top-5 Lexical (BM25)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-3099 | 15,7636 | 0 | shed×1, light×1, new×1 | 139 | >100 | The aryl hydrocarbon receptor and its xenobiotic ligands: a fundamental trigger for car... |
| 2 | MED-4872 | 12,8916 | 0 | vitamin×14, light×1, recommend×2 | 370 (truncado) | 16 | Safety considerations and potential interactions of vitamins: should vitamins be consid... |
| 3 | MED-3373 | 12,4090 | 0 | shed×1, light×1, recommend×1 | 258 (truncado) | >100 | The Influence of Social Involvement, Neighborhood Aesthetics, and Community Garden Part... |
| 4 | MED-1579 | 10,5638 | 0 | shed×1, light×1 | 246 | >100 | Crohn's disease: a review of treatment options and current research. |
| 5 | MED-1777 | 10,3188 | 0 | shed×1, light×1 | 276 (truncado) | >100 | Shedding Light on the Controversy Surrounding the Temporal Decline in Human Sperm Count... |

### Top-5 Semântico (cosseno)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-714 | 0,7415 | 2 | vitamin×10, recommend×1 | 323 (truncado) | 25 | Towards prevention of vitamin D deficiency and beyond: knowledge gaps and research need... |
| 2 | MED-3988 | 0,6959 | 0 | vitamin×24 | 459 (truncado) | 69 | Vitamin D2 Is as Effective as Vitamin D3 in Maintaining Circulating Concentrations of 2... |
| 3 | MED-3987 | 0,6767 | 0 | vitamin×15 | 390 (truncado) | 73 | Comparison of vitamin D2 and vitamin D3 supplementation in raising serum 25-hydroxyvita... |
| 4 | MED-919 | 0,6636 | 2 | vitamin×7, recommend×3 | 325 (truncado) | 12 | Evaluation, treatment, and prevention of vitamin D deficiency: an Endocrine Society cli... |
| 5 | MED-3990 | 0,6481 | 0 | vitamin×20 | 703 (truncado) | 76 | Vitamin D supplementation for prevention of mortality in adults. |

## PLAIN-1537: "low-carb diets"

- NDCG@10: lexical 0,0000, semântico 0,6618, diferença (semântico − lexical) 0,6618
- Documentos relevantes nos qrels: 45; com pelo menos um termo da consulta: 25
- Termos da consulta no índice: `lowcarb` (1 docs), `diet` (1029 docs)

### Top-5 Lexical (BM25)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-4880 | 17,0677 | 0 | lowcarb×7, diet×11 | 406 (truncado) | 2 | Effects of very-low-carbohydrate (horsemeat- or beef-based) diets and restricted feedin... |
| 2 | MED-4848 | 2,5754 | 0 | diet×14 | 303 (truncado) | >100 | Vegetarian diet for patients with rheumatoid arthritis--status: two years after introdu... |
| 3 | MED-5267 | 2,5655 | 0 | diet×14 | 358 (truncado) | >100 | Mediterranean and low-fat diets improve endothelial function in hypercholesterolemic men. |
| 4 | MED-1374 | 2,5462 | 0 | diet×8 | 139 | >100 | Definitions and potential health benefits of the Mediterranean diet: views from experts... |
| 5 | MED-3786 | 2,5454 | 0 | diet×9 | 211 | >100 | Choline- and betaine-defined diets for use in clinical research and for the management ... |

### Top-5 Semântico (cosseno)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-4515 | 0,6623 | 1 | diet×11 | 564 (truncado) | 49 | The effect of a plant-based low-carbohydrate ("Eco-Atkins") diet on body weight and blo... |
| 2 | MED-4880 | 0,6094 | 0 | lowcarb×7, diet×11 | 406 (truncado) | 1 | Effects of very-low-carbohydrate (horsemeat- or beef-based) diets and restricted feedin... |
| 3 | MED-4514 | 0,5962 | 1 | diet×7 | 648 (truncado) | >100 | Low-carbohydrate diets and all-cause and cause-specific mortality: Two cohort Studies |
| 4 | MED-1616 | 0,5870 | 1 | diet×6 | 529 (truncado) | >100 | Very-low-carbohydrate ketogenic diet v. low-fat diet for long-term weight loss: a meta-... |
| 5 | MED-2586 | 0,5584 | 1 | diet×2 | 511 (truncado) | >100 | Systematic review and meta-analysis of clinical trials of the effects of low carbohydra... |

## PLAIN-418: "Fresh fruit versus frozen--which is better?"

- NDCG@10: lexical 0,2057, semântico 0,8671, diferença (semântico − lexical) 0,6614
- Documentos relevantes nos qrels: 3; com pelo menos um termo da consulta: 3
- Termos da consulta no índice: `fresh` (100 docs), `fruit` (333 docs), `versu` (157 docs), `frozenwhich` (0 docs), `better` (179 docs)

### Top-5 Lexical (BM25)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-3469 | 11,8108 | 0 | fresh×1, fruit×3, versu×1 | 242 | 11 | Postprandial glycemic response to orange juice and nondiet cola: is there a difference? |
| 2 | MED-3203 | 11,3547 | 0 | fresh×4, versu×7 | 550 (truncado) | >100 | Red grapefruit positively influences serum triglyceride level in patients suffering fro... |
| 3 | MED-2453 | 11,2948 | 0 | fresh×8, fruit×9 | 393 (truncado) | 12 | Effect of fresh fruit consumption on lung function and wheeze in children |
| 4 | MED-5327 | 10,8290 | 0 | fresh×2, fruit×2, better×1 | 364 (truncado) | >100 | The association between dietary patterns and mental health in early adolescence. |
| 5 | MED-917 | 10,4372 | 2 | fresh×3, fruit×4 | 297 (truncado) | 1 | Effect of freezing and storage on the phenolics, ellagitannins, flavonoids, and antioxi... |

### Top-5 Semântico (cosseno)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-917 | 0,5815 | 2 | fresh×3, fruit×4 | 297 (truncado) | 5 | Effect of freezing and storage on the phenolics, ellagitannins, flavonoids, and antioxi... |
| 2 | MED-3714 | 0,5303 | 2 | fresh×4 | 332 (truncado) | 39 | Differences in antioxidant levels of fresh, frozen and freeze-dried strawberries and st... |
| 3 | MED-3738 | 0,4904 | 0 | fresh×2, fruit×5 | 574 (truncado) | 13 | Comparison of health-relevant flavonoids in commonly consumed cranberry products. |
| 4 | MED-3946 | 0,4899 | 0 | fruit×3 | 466 (truncado) | >100 | Antioxidant capacity and other bioactivities of the freeze-dried Amazonian palm berry, ... |
| 5 | MED-2285 | 0,4745 | 0 | fresh×1, fruit×2 | 374 (truncado) | 34 | Processed tart cherry products--comparative phytochemical content, in vitro antioxidant... |

# Maior vantagem do sistema lexical

## PLAIN-1473: "kohlrabi"

- NDCG@10: lexical 1,0000, semântico 0,0000, diferença (semântico − lexical) -1,0000
- Documentos relevantes nos qrels: 1; com pelo menos um termo da consulta: 1
- Termos da consulta no índice: `kohlrabi` (1 docs)

### Top-5 Lexical (BM25)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-4455 | 11,5988 | 1 | kohlrabi×2 | 329 (truncado) | >100 | Glucoraphanin and 4-hydroxyglucobrassicin contents in seeds of 59 cultivars of broccoli... |

### Top-5 Semântico (cosseno)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-3947 | 0,2202 | 0 | nenhum | 439 (truncado) | >100 | Hibiscus anthocyanins rich extract-induced apoptotic cell death in human promyelocytic ... |
| 2 | MED-4660 | 0,2173 | 0 | nenhum | 307 (truncado) | >100 | Variability of iodine content in common commercially available edible seaweeds. |
| 3 | MED-3441 | 0,2156 | 0 | nenhum | 167 | >100 | Marine edible algae as disease preventers. |
| 4 | MED-3447 | 0,2128 | 0 | nenhum | 254 | >100 | Seaweed prevents breast cancer? |
| 5 | MED-5024 | 0,2125 | 0 | nenhum | 249 | >100 | Disseminated chlorellosis in a dog. |

## PLAIN-1288: "grapes"

- NDCG@10: lexical 0,8900, semântico 0,1299, diferença (semântico − lexical) -0,7601
- Documentos relevantes nos qrels: 196; com pelo menos um termo da consulta: 15
- Termos da consulta no índice: `grape` (29 docs)

### Top-5 Lexical (BM25)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-2668 | 9,3516 | 1 | grape×7 | 199 | 15 | Concord grape juice supplementation and neurocognitive function in human aging. |
| 2 | MED-2669 | 9,1571 | 1 | grape×7 | 269 (truncado) | 13 | Concord grape juice supplementation improves memory function in older adults with mild ... |
| 3 | MED-2083 | 8,9203 | 0 | grape×7 | 384 (truncado) | 5 | Grape juice, but not orange juice or grapefruit juice, inhibits human platelet aggregat... |
| 4 | MED-1538 | 8,8955 | 1 | grape×7 | 401 (truncado) | 26 | A premeal snack of raisins decreases mealtime food intake more than grapes in young chi... |
| 5 | MED-5065 | 8,7620 | 1 | grape×5 | 330 (truncado) | 20 | Anthocyanin-rich grape extract blocks breast cell DNA damage. |

### Top-5 Semântico (cosseno)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-3200 | 0,4264 | 0 | nenhum | 314 (truncado) | >100 | Prospective study of grapefruit intake and risk of breast cancer in postmenopausal wome... |
| 2 | MED-3207 | 0,4250 | 0 | nenhum | 223 | >100 | The grapefruit: an old wine in a new glass? Metabolic and cardiovascular perspectives |
| 3 | MED-398 | 0,4250 | 0 | nenhum | 223 | >100 | The grapefruit: an old wine in a new glass? Metabolic and cardiovascular perspectives |
| 4 | MED-3210 | 0,4243 | 0 | nenhum | 433 (truncado) | >100 | The effects of daily consumption of grapefruit on body weight, lipids, and blood pressu... |
| 5 | MED-2083 | 0,4141 | 0 | grape×7 | 384 (truncado) | 3 | Grape juice, but not orange juice or grapefruit juice, inhibits human platelet aggregat... |

## PLAIN-792: "cadaverine"

- NDCG@10: lexical 0,6448, semântico 0,1009, diferença (semântico − lexical) -0,5440
- Documentos relevantes nos qrels: 6; com pelo menos um termo da consulta: 3
- Termos da consulta no índice: `cadaverin` (3 docs)

### Top-5 Lexical (BM25)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-4958 | 11,8863 | 1 | cadaverin×4 | 362 (truncado) | 7 | Biogenic amines in fish: roles in intoxication, spoilage, and nitrosamine formation--a ... |
| 2 | MED-4546 | 11,8447 | 1 | cadaverin×6 | 597 (truncado) | 14 | Acute and subacute toxicity of tyramine, spermidine, spermine, putrescine and cadaverin... |
| 3 | MED-4547 | 7,4995 | 1 | cadaverin×1 | 346 (truncado) | >100 | Determination of biogenic amines in Korean traditional fermented soybean paste (Doenjang). |

### Top-5 Semântico (cosseno)

| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |
|---|---|---|---|---|---|---|---|
| 1 | MED-729 | 0,3029 | 0 | nenhum | 319 (truncado) | >100 | Transfer of spinal cord material to subsequent bovine carcasses at splitting. |
| 2 | MED-3601 | 0,2870 | 0 | nenhum | 202 | >100 | Children as guinea pigs: historical perspective. |
| 3 | MED-732 | 0,2819 | 0 | nenhum | 185 | >100 | Dissemination of central nervous system tissue during the slaughter of cattle in three ... |
| 4 | MED-1037 | 0,2642 | 0 | nenhum | 130 | >100 | A brief journey into medical care and disease in ancient Egypt. |
| 5 | MED-1041 | 0,2573 | 0 | nenhum | 151 | >100 | Gastroenterology in ancient Egypt. |

