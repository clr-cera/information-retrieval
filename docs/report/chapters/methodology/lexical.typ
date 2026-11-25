== Busca lexical (BM25)

O baseline lexical é o *BM25* (`ProbabilisticModel`, reaproveitado do TP1), usado em todos os experimentos seguintes:

$ "score"(d, q) = sum_(t in q) "IDF"(t) dot (t f(t, d) (k_1 + 1)) / (t f(t, d) + k_1 (1 - b + b |d| \/ "avgdl")), quad "IDF"(t) = log(1 + (N - n_t + "0,5") / (n_t + "0,5")) $

A escolha se apoia em três evidências. No TP1 (Cranfield), o BM25 superou o Modelo Vetorial em MAP e na curva Precision × Recall. No dev do NFCorpus, teve NDCG\@10 de 0,2906, contra 0,2880 do TF-IDF com cosseno. E os seus parâmetros têm interpretação direta: $k_1$ controla a saturação do $t f$, e $b$, a normalização pelo tamanho do documento.

Na grade $k_1 in {"0,5"; "1,2"; "2,0"}$ × $b in {0; "0,75"; "1,0"}$ no dev, o NDCG\@10 variou só entre 0,2854 e 0,2916. O maior valor ($k_1 = "2,0"$, $b = 0$) ficou apenas 0,001 acima dos *valores usuais* ($k_1 = "1,2"$, $b = "0,75"$), que foram adotados por causa dos *empates de score*. Com $b = 0$, documentos com as mesmas frequências dos mesmos termos empatam: 93 das 324 consultas do dev tinham empate entre a 10ª e a 11ª posição, e só a ordem de desempate fazia o NDCG\@10 variar de 0,2850 a 0,3021. Com $b = "0,75"$, só 3 consultas empatam, e a variação fica entre 0,2899 e 0,2915. O efeito pequeno de $b$ é coerente com os dados: 80% dos documentos têm entre 87 e 212 termos, e os relevantes do dev têm o mesmo tamanho médio da coleção (156,2 e 155,0 termos).
