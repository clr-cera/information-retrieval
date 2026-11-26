# Análise do reranking

- Consultas: 323; NDCG@10 melhorou em 108, piorou em 97, não mudou em 118
- Consultas em que o top-10 mudou (ordem ou conteúdo): 323

## maior ganho: PLAIN-2081 — "shelf life"

- NDCG@10: híbrido 0,0000, com reranking 1,0000; relevantes nos qrels: 1
- Relevantes entre os 50 candidatos reordenados: 1

| Documento | Grau | Pos. híbrido | Pos. reranking | Score cross-encoder | Par > 512 tokens | Título |
|---|---|---|---|---|---|---|
| MED-4303 | 1 | 34 | 1 | 0,8503 | não | Oxidative stability and shelf-life evaluation of selected culinary oils. |
| MED-2700 | 0 | 6 | 2 | -1,3671 | não | The effect of blood removal on oxidation and shelf life of broiler breast meat. |
| MED-859 | 0 | 8 | 3 | -3,2820 | não | gamma-Irradiation dose: effects on baby-leaf spinach ascorbic acid, carotenoi... |
| MED-2074 | 0 | 7 | 4 | -3,8732 | não | Modifying the processing and handling of frozen broccoli for increased sulfor... |
| MED-1182 | 0 | 3 | 5 | -3,9809 | não | Fruit and Soil Quality of Organic and Conventional Strawberry Agroecosystems |
| MED-2810 | 0 | 13 | 6 | -7,7355 | não | Curcumin as "Curecumin": from kitchen to clinic. |
| MED-3170 | 0 | 27 | 7 | -7,8221 | sim | Cognitive Changes and Quality of Life in Neurocysticercosis: A Longitudinal S... |
| MED-4180 | 0 | 24 | 8 | -8,3249 | não | Half-lives of serum PCB congener concentrations in environmentally exposed ea... |
| MED-4716 | 0 | 28 | 9 | -8,5413 | sim | The fruit of the date palm: its possible use as the best food for the future? |
| MED-2510 | 0 | 1 | 10 | -8,6189 | não | Comparative and meta-analytic insights into life extension via dietary restri... |

## segundo maior ganho: PLAIN-681 — "betel nuts"

- NDCG@10: híbrido 0,0000, com reranking 1,0000; relevantes nos qrels: 1
- Relevantes entre os 50 candidatos reordenados: 1

| Documento | Grau | Pos. híbrido | Pos. reranking | Score cross-encoder | Par > 512 tokens | Título |
|---|---|---|---|---|---|---|
| MED-5017 | 1 | 12 | 1 | 4,3069 | não | Association between betel-nut chewing and chronic kidney disease in men. |
| MED-4030 | 0 | 9 | 2 | -2,1335 | não | Diet and prevention of oral cancer: strategies for clinical practice. |
| MED-4289 | 0 | 17 | 3 | -2,8389 | sim | Nut consumption is associated with decreased health risk factors for cardiova... |
| MED-4288 | 0 | 26 | 4 | -4,5136 | sim | Out-of-hand nut consumption is associated with improved nutrient intake and h... |
| MED-2595 | 0 | 2 | 5 | -4,8145 | não | Health benefits of nut consumption with special reference to body weight cont... |
| MED-4286 | 0 | 7 | 6 | -4,8713 | não | Nuts and healthy body weight maintenance mechanisms. |
| MED-1387 | 0 | 28 | 7 | -4,9092 | sim | Nut consumption and risk of type 2 diabetes, cardiovascular disease, and all-... |
| MED-4301 | 0 | 23 | 8 | -5,0103 | não | Nut consumption and blood lipid levels: a pooled analysis of 25 intervention ... |
| MED-4706 | 0 | 14 | 9 | -5,0975 | não | Regular Consumption of Nuts Is Associated with a Lower Risk of Cardiovascular... |
| MED-4298 | 0 | 24 | 10 | -5,6028 | não | Effects of almond consumption on the reduction of LDL-cholesterol: a discussi... |

## pouca ou nenhuma alteração: PLAIN-1039 — "domoic acid"

- NDCG@10: híbrido 1,0000, com reranking 1,0000; relevantes nos qrels: 2
- Relevantes entre os 50 candidatos reordenados: 2

| Documento | Grau | Pos. híbrido | Pos. reranking | Score cross-encoder | Par > 512 tokens | Título |
|---|---|---|---|---|---|---|
| MED-4380 | 1 | 1 | 1 | 7,9410 | não | Domoic acid and human exposure risks: a review. |
| MED-4381 | 1 | 2 | 2 | 4,9260 | não | Amnesic shellfish poison. |
| MED-4995 | 0 | 3 | 3 | -3,6346 | não | Salicylic Acid sans Aspirin in Animals and Man: Persistence in Fasting and Bi... |
| MED-5202 | 0 | 19 | 4 | -4,0890 | não | Synthesis and stability study of a new major metabolite of γ-hydroxybutyric acid |
| MED-4092 | 0 | 24 | 5 | -5,3947 | não | Uric acid: A marker of increased cardiovascular risk. |
| MED-4628 | 0 | 41 | 6 | -6,2091 | não | An association between dietary arachidonic acid, measured in adipose tissue, ... |
| MED-3492 | 0 | 47 | 7 | -6,3004 | sim | Effects of a natural extract of (-)-hydroxycitric acid (HCA-SX) and a combina... |
| MED-4176 | 0 | 27 | 8 | -6,3390 | sim | Perfluorooctanesulfonate and related fluorochemicals in human blood samples f... |
| MED-2754 | 0 | 46 | 9 | -6,4052 | não | Efficacy of omega-3 fatty acid supplements (eicosapentaenoic acid and docosah... |
| MED-846 | 0 | 10 | 10 | -6,4721 | não | Antifungal mechanisms supporting boric acid therapy of Candida vaginitis. |

## maior piora: PLAIN-1679 — "myelopathy"

- NDCG@10: híbrido 0,3869, com reranking 0,0000; relevantes nos qrels: 1
- Relevantes entre os 50 candidatos reordenados: 1

| Documento | Grau | Pos. híbrido | Pos. reranking | Score cross-encoder | Par > 512 tokens | Título |
|---|---|---|---|---|---|---|
| MED-1105 | 0 | 32 | 1 | 0,1933 | não | A CASE OF MULTIPLE MYELOMA PRESENTING AS A BULLOUS DERMATOSIS |
| MED-1104 | 0 | 24 | 2 | -0,9343 | não | Multiple myeloma : recent progress in diagnosis and treatment. |
| MED-1107 | 0 | 8 | 3 | -2,3799 | não | From myeloma precursor disease to multiple myeloma: new diagnostic concepts a... |
| MED-3193 | 0 | 3 | 4 | -2,5360 | não | 11C-choline vs. 18F-FDG PET/CT in assessing bone involvement in patients with... |
| MED-3787 | 0 | 4 | 5 | -2,5360 | não | 11C-choline vs. 18F-FDG PET/CT in assessing bone involvement in patients with... |
| MED-1111 | 0 | 19 | 6 | -2,8787 | não | Clinical Trials and Observations: Monoclonal gammopathy of undetermined signi... |
| MED-1115 | 0 | 10 | 7 | -3,4641 | não | Disparities in the prevalence, pathogenesis and progression of monoclonal gam... |
| MED-1109 | 0 | 14 | 8 | -3,8244 | não | Risk factors for multiple myeloma: a hospital-based case-control study in Nor... |
| MED-1113 | 0 | 2 | 9 | -4,1136 | não | Monoclonal gammopathy of undetermined significance, smoldering multiple myelo... |
| MED-4312 | 0 | 39 | 10 | -5,2228 | não | Post-epidemic eosinophilia myalgia syndrome associated with L-Tryptophan |
| MED-5142 | 1 | 5 | 40 | -10,2031 | não | Irreversible subacute sclerotic combined degeneration of the spinal cord in a... |

