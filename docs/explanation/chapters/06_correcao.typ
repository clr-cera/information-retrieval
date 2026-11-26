#import "../estilo.typ": *

= Correção ortográfica (`ir/lexical.py`) <cap-correcao>

== Teoria

Na busca lexical, um termo digitado errado não existe no índice e é descartado. Em consultas curtas isso apaga a informação principal: "fenugbreek" em vez de "fenugreek" deixa a consulta vazia. A correção troca cada termo desconhecido pela palavra mais parecida do vocabulário, em três etapas, da mais barata para a mais cara:

+ *Candidatos por k-gramas.* Um k-grama é uma sequência de $k$ caracteres, com `^` e `$` marcando início e fim: com $k = 2$, `food` → `^f fo oo od d$`. Um índice *k-grama → termos* dá como candidatos só os termos que compartilham algum k-grama com o termo errado, em vez das 36 mil palavras do dicionário.
+ *Filtro pelo Jaccard.* $J(A, B) = |A inter B| \/ |A union B|$ sobre os conjuntos de k-gramas. `food` × `foodo`: 4 bigramas em comum, 7 no total, $J approx "0,571"$. Candidatos abaixo do limiar saem.
+ *Distância de edição (Levenshtein).* Menor número de inserções, remoções e substituições que leva uma palavra à outra, calculado por programação dinâmica. A troca de duas letras vizinhas (`practices` → `parctices`) custa 2, porque não há operação de troca.

O escolhido é o candidato de menor distância; empates são decididos pelo maior Jaccard, depois pela maior frequência na coleção e por fim pela ordem alfabética.

== O que o código faz

- *Dicionário* (`build_dictionary`): conta os termos da coleção só com tokenização e minúsculas, *sem* stopwords nem stemming — a correção precisa propor palavras reais (`studies`, não `studi`), e o enunciado exige isso. São 36.477 termos.
- *Corretor* (`SpellingCorrector`): monta o índice de k-gramas no construtor e aplica as três etapas a cada termo desconhecido da consulta; termos conhecidos ficam como estão, e um termo sem candidatos também. A configuração usada, escolhida no dev, é $k = 2$, Jaccard $>= "0,2"$ e distância $<= 2$.
- *Geração de erros*: para o experimento, `generate_error_variants` gera todas as variantes de um termo para um dos quatro tipos do enunciado (inserção, remoção, substituição, transposição). `inject_error` mantém só as variantes que *não* estão no vocabulário — um erro que forma outra palavra válida (`food` → `good`) não seria detectável — e sorteia uma. `inject_query_error` escolhe o termo da consulta a alterar: o mais longo com pelo menos 4 letras que esteja no vocabulário e não seja stopword.

== Ajuste e experimento

`tune_typo.py` gera 200 erros simulados em consultas do dev e testa a grade $k in {2, 3}$ × Jaccard $in {"0,2"; "0,3"; "0,4"; "0,5"}$ × distância $in {1, 2, 3}$, medindo a fração corrigida exatamente. A configuração escolhida acertou *92%*; com distância máxima 1, o acerto cai para cerca de 71%, porque as transposições custam 2.

`run_typo.py` pega as 10 primeiras consultas do test com NDCG\@10 maior que zero, injeta um erro por consulta (alternando os tipos), corrige e mede o NDCG\@10 das três versões no BM25. Resultado: *0,4706* na original, *0,1625* com erro e *0,4706* após a correção; as 10 correções recuperaram a palavra original. `analyze_typo.py` confere as regras do enunciado (um único termo alterado, termo com erro fora do dicionário etc.) e monta a tabela do relatório.
