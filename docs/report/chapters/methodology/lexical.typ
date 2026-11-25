== Busca lexical (BM25)

O baseline lexical é o *BM25*, reaproveitado do TP1 (`ProbabilisticModel`, `src/ir/lexical.py`) e usado em todos os experimentos seguintes:

$ "score"(d, q) = sum_(t in q) "IDF"(t) dot (t f(t, d) (k_1 + 1)) / (t f(t, d) + k_1 (1 - b + b |d| \/ "avgdl")), quad "IDF"(t) = log(1 + (N - n_t + "0,5") / (n_t + "0,5")) $

Cada termo distinto da consulta conta uma vez. A escolha do BM25 se apoia em três evidências: no TP1 (Cranfield), ele superou o Modelo Vetorial na curva Precision × Recall e no MAP em todos os pipelines; no dev do NFCorpus, com o mesmo pré-processamento, teve NDCG\@10 de 0,2906, contra 0,2880 do TF-IDF com cosseno (o TF-IDF vence mais consultas, 86 × 82, mas o BM25 vence por margens maiores), uma vantagem pequena; e o BM25 tem parâmetros com interpretação direta ($k_1$ controla a saturação do $t f$ e $b$, a normalização pelo tamanho do documento) e é o baseline lexical do BEIR.

Os parâmetros foram avaliados no dev, na grade $k_1 in {"0,5"; "1,2"; "2,0"}$ × $b in {0; "0,75"; "1,0"}$. Todo o intervalo ficou entre 0,2854 e 0,2916 de NDCG\@10. O maior valor foi $k_1 = "2,0"$ e $b = 0$ (0,2916), apenas 0,001 acima dos *valores usuais*, $k_1 = "1,2"$ e $b = "0,75"$ (0,2906), que foram adotados. O motivo são os *empates de score*: com $b = 0$, o score só depende de $t f$ e IDF, e documentos com as mesmas frequências dos mesmos termos empatam. No dev, 93 das 324 consultas tinham empate entre a 10ª e a 11ª posição, e só a ordem de desempate fazia o NDCG\@10 variar de 0,2850 a 0,3021, muito mais que a vantagem de 0,001. Com $b = "0,75"$, só 3 consultas têm esse empate, e a variação cai para 0,2899–0,2915. Os empates restantes seguem a ordem das posting lists (determinística).

O pequeno efeito de $b$ tem explicação nos dados: os documentos têm tamanho homogêneo (80% entre 87 e 212 termos) e a relevância não depende do tamanho (os relevantes do dev têm em média 156,2 termos, contra 155,0 da coleção).
