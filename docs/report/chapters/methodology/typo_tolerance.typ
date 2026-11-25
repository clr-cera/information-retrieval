== Tolerância a erros

A classe `SpellingCorrector` (`src/ir/lexical.py`) corrige só os termos da consulta que *não* estão no dicionário, formado pelos 36.477 termos da coleção antes do stemming e da remoção de stopwords, com as suas frequências. Para cada termo desconhecido:

+ *Candidatos por k-gramas:* os termos que compartilham ao menos um k-grama com ele, obtidos de um índice de k-gramas (com marcadores de início e fim: `^f`, `fo`, `oo`, `od`, `d$` para `food`).
+ *Filtro pelo coeficiente de Jaccard* entre os conjuntos de k-gramas, com um limiar mínimo.
+ *Seleção pela distância de Levenshtein*, com uma distância máxima. Vence o candidato mais próximo; empates são resolvidos pelo maior Jaccard e depois pela maior frequência.

Os limiares foram escolhidos no dev, pela fração de 200 erros simulados corrigidos exatamente, na grade $k in {2, 3}$ × Jaccard $>= {"0,2"; "0,3"; "0,4"; "0,5"}$ × distância $<= {1, 2, 3}$. A melhor configuração foi *bigramas, Jaccard $>= "0,2"$ e distância $<= 2$*, com 92,0% de acerto. Com distância máxima 1, o acerto cai para cerca de 71%, porque a troca de ordem de dois caracteres custa 2.

O experimento (`run_typo.py`, seed 42) usa as 10 primeiras consultas do test, em ordem de identificador, com NDCG\@10 original maior que zero. Em cada uma, o erro atinge o termo mais longo que não é stopword e tem ao menos 4 letras. O tipo alterna entre inserção, remoção, substituição e troca de ordem, e é sorteada uma variante que não existe no dicionário. As três versões da consulta são avaliadas no BM25, e a recuperação é $("NDCG"_"corr" - "NDCG"_"erro") \/ ("NDCG"_"orig" - "NDCG"_"erro")$ quando o denominador é positivo. Como o erro atinge o termo mais específico, o cenário é desfavorável. A aplicação ao sistema semântico (opcional) não foi feita.
