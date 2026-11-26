== Tolerância a erros

A classe `SpellingCorrector` (`src/ir/lexical.py`) corrige só os termos da consulta que não estão no dicionário (como possíveis erros de digitação), formado pelos 36.477 termos da coleção antes do stemming e da remoção de stopwords, com as suas frequências. Para cada termo que não tiver correspondência no dicionário, seguem-se os seguintes passos:

+ *Candidatos por k-gramas:* os termos que compartilham ao menos um k-grama com ele, obtidos de um índice de k-gramas (com marcadores de início e fim: `^f`, `fo`, `oo`, `od`, `d$` para `food`).
+ *Filtro por coeficiente de Jaccard:* entre os candidatos, descarta os com coeficiente de Jaccard abaixo de $"0,2"$.
+ *Seleção por distância de Levenshtein*: Vence o candidato mais próximo. A distância máxima é $2$. Empates são resolvidos pelo maior Jaccard e depois pela maior frequência do termo do dicionário.

Os limiares foram escolhidos no dev, pcom 200 erros simulados com correção exata (@tab-typo-grid).

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, 1fr, 1fr, 1fr, 1fr),
      align: (left, right, right, right, right),
      table.header([*k-grama*], [*Jaccard $>=$*], [*Dist. $<= 1$*], [*Dist. $<= 2$*], [*Dist. $<= 3$*]),
      [2], [0,2], [71,5%], [*92,0%*], [92,0%],
      [2], [0,3], [71,5%], [92,0%], [92,0%],
      [2], [0,4], [71,5%], [91,5%], [91,5%],
      [2], [0,5], [71,0%], [88,5%], [88,5%],
      [3], [0,2], [69,5%], [87,5%], [87,5%],
      [3], [0,3], [68,0%], [85,0%], [85,0%],
      [3], [0,4], [62,5%], [74,5%], [74,5%],
      [3], [0,5], [52,0%], [58,0%], [58,0%],
    )
  },
  caption: [Acerto da correção no dev.],
) <tab-typo-grid>

A melhor configuração foi *bigramas, Jaccard $>= "0,2"$ e distância $<= 2$*, com 92,0% de acerto. Ela empata com Jaccard $>= "0,3"$ e com distância $<= 3$. Foram escolhidos os bigramas, pois um erro de digitação tende a alterar mais letras próximas (e mais bigramas combinam com o termo correto). Pelo mesmo motivo, foi escolhida a menor distância de Levenshtein.

O experimento (`run_typo.py`, seed 42) usa as 10 primeiras consultas do test, em ordem de id, com NDCG\@10 original maior que zero (consultas válidas na coleção). O tipo de erro alterna entre inserção, remoção, substituição e troca de ordem (@tab-typo-types), e é sorteada uma variante que não existe no dicionário.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1.5fr, 2.4fr, 1.9fr, 1fr),
      align: (left, left, left, right),
      table.header([*Tipo*], [*Operação*], [*Exemplo (test)*], [*Levenshtein*]),
      [Inserção], [acrescenta um caractere], [childhood → childhnood], [1],
      [Remoção], [apaga um caractere], [domoic → omoic], [1],
      [Substituição], [troca um caractere por outro], [ecmo → ecco], [1],
      [Troca de ordem], [inverte dois caracteres vizinhos], [disruptors → disrputors], [2],
    )
  },
  caption: [Tipos de erros simulados.],
) <tab-typo-types>

As três versões da consulta (original, com erro e corrigida) são avaliadas no BM25. A qualidade de recuperação (de 0 a 1) recuperação é dada por:

$ "recuperação" = ("NDCG"_"corr" - "NDCG"_"erro") / ("NDCG"_"orig" - "NDCG"_"erro") $