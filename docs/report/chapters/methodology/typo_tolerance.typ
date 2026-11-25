== Tolerância a erros

O sistema corrige termos desconhecidos da consulta antes da busca lexical, em três etapas: geração de candidatos por k-gramas, filtragem pelo coeficiente de Jaccard e seleção pela distância de edição. A implementação é a classe `SpellingCorrector` (`src/ir/lexical.py`). A correção ortográfica é um experimento separado: os demais experimentos usam as consultas originais, sem correção.

=== Dicionário

O dicionário é formado pelos termos da coleção *antes* do stemming e da remoção de stopwords, como exige o enunciado: o texto de cada documento (título + texto) passa apenas pela tokenização e pela conversão para minúsculas. O resultado tem 36.477 termos, cada um com a sua frequência na coleção. Assim, toda correção é uma palavra que realmente aparece nos documentos, e a consulta corrigida passa depois pelo mesmo pré-processamento das demais.

Um termo da consulta só é corrigido quando *não* está no dicionário. Termos conhecidos nunca são alterados, mesmo que exista uma palavra parecida mais frequente.

=== Correção de um termo

+ *Geração de candidatos por k-gramas.* Cada termo do dicionário é decomposto nos seus k-gramas, com marcadores de início e fim de palavra (com $k = 2$, `food` gera `^f`, `fo`, `oo`, `od` e `d$`). Um índice invertido de k-gramas associa cada k-grama aos termos que o contêm. Os candidatos para um termo desconhecido são todos os termos do dicionário que compartilham pelo menos um k-grama com ele.
+ *Filtragem pelo coeficiente de Jaccard.* Para cada candidato, calcula-se o Jaccard entre os conjuntos de k-gramas, $J(A, B) = |A inter B| \/ |A union B|$. Candidatos com $J$ abaixo do limiar são descartados. Essa etapa elimina, de forma barata, termos que compartilham poucos k-gramas com o termo desconhecido.
+ *Seleção pela distância de edição.* Para os candidatos restantes, calcula-se a distância de Levenshtein (inserção, remoção e substituição de caracteres, com custo 1 cada). Candidatos acima da distância máxima são descartados. A correção é o candidato com menor distância; empates são resolvidos pelo maior Jaccard, depois pela maior frequência na coleção e, por fim, pela ordem alfabética.

Se nenhum candidato passa pelos filtros, o termo é mantido como está.

=== Ajuste dos limiares no dev

O tamanho dos k-gramas, o limiar de Jaccard e a distância máxima foram ajustados no conjunto dev (script `tune_typo.py`), sobre a grade $k in {2, 3}$ × $J >= {"0,2"; "0,3"; "0,4"; "0,5"}$ × distância $<= {1, 2, 3}$. Para isso, foram gerados 200 erros a partir de termos das consultas do dev, alternando os quatro tipos de erro, e cada configuração foi medida pela fração de erros corrigidos exatamente para o termo original.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: 4,
      align: (left, right, right, right),
      table.header([*Configuração*], [*Distância* $<= 1$], [*Distância* $<= 2$], [*Distância* $<= 3$]),
      [$k = 2$, $J >= "0,2"$], [71,5%], [*92,0%*], [92,0%],
      [$k = 2$, $J >= "0,5"$], [71,0%], [88,5%], [88,5%],
      [$k = 3$, $J >= "0,2"$], [69,5%], [87,5%], [87,5%],
      [$k = 3$, $J >= "0,5"$], [52,0%], [58,0%], [58,0%],
    )
  },
  caption: [Fração dos 200 erros do dev corrigidos exatamente, para algumas configurações da grade. Em negrito, a configuração selecionada.],
) <tab-typo-tuning>

A configuração selecionada foi $k = 2$, $J >= "0,2"$ e distância $<= 2$, com 92,0% de acerto. Três padrões explicam a tabela:

- *Distância máxima 1 é insuficiente.* A troca de ordem de dois caracteres (transposição) custa 2 na distância de Levenshtein, que não tem uma operação própria para ela. Com distância máxima 1, essas correções são descartadas, e o acerto cai para cerca de 71%. Aumentar para 3 não muda o acerto, porque todos os erros gerados estão a no máximo 2 edições.
- *Bigramas funcionam melhor do que trigramas.* Uma única alteração em uma palavra curta destrói uma fração grande dos seus trigramas, o que reduz o Jaccard e faz o termo correto ser filtrado. Com bigramas, mais k-gramas sobrevivem ao erro.
- *Limiares de Jaccard altos descartam a palavra correta*, sobretudo com trigramas (58% com $k = 3$ e $J >= "0,5"$).

=== Protocolo do experimento

O experimento usa 10 consultas do conjunto test e é executado pelo script `run_typo.py`, com seed fixa (42), o que o torna reprodutível:

- *Escolha das consultas.* São as 10 primeiras consultas do test, em ordem de identificador, que têm NDCG\@10 maior que zero no sistema lexical (exigência do enunciado) e em que é possível gerar um erro válido. A escolha é automática, sem selecionar consultas favoráveis.
- *Escolha do termo.* Em cada consulta, o erro é aplicado ao termo mais longo que não é stopword, tem pelo menos 4 letras e está no dicionário.
- *Geração do erro.* Os tipos de erro se alternam de uma consulta para a outra: inserção, remoção, substituição e troca da ordem de dois caracteres. Dentre todas as variantes possíveis do termo para aquele tipo, sorteia-se uma que *não* exista no dicionário, como exige o enunciado (erros que geram outra palavra válida não seriam detectados).
- *Avaliação.* Cada consulta é avaliada no sistema lexical (BM25, com os mesmos parâmetros dos demais experimentos) em três versões: original, com erro e corrigida. A recuperação é calculada por consulta como $("NDCG@10"_"corrigida" - "NDCG@10"_"erro") \/ ("NDCG@10"_"original" - "NDCG@10"_"erro")$, quando o denominador é maior que zero; caso contrário, registra-se que o erro não reduziu o desempenho.

A escolha do termo mais longo tem uma consequência importante: o erro tende a atingir o termo mais específico da consulta, que costuma ser o mais importante para o ranking. O experimento, portanto, mede um cenário desfavorável, em que o erro afeta justamente o termo que mais contribui para a busca.

O script `analyze_typo.py` confere automaticamente as regras do enunciado no resultado: NDCG\@10 original maior que zero, exatamente um termo alterado por consulta, termo com erro fora do dicionário e termo original presente no dicionário. Todas as 10 consultas passaram nessas verificações.

Aplicar as mesmas consultas com erro ao sistema semântico era opcional e *não* foi feito. Esse experimento permitiria avaliar se os embeddings, que trabalham com subpalavras, são mais robustos a erros de digitação do que o BM25, que depende da correspondência exata de termos.
