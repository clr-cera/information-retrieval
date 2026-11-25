== Pré-processamento

Cada documento é representado pela concatenação de título e texto, em todos os sistemas (lexical, semântico e reranking). No sistema lexical, documentos e consultas passam pelo mesmo pré-processamento, implementado com o NLTK 3.10.3 e reaproveitado do TP1 (`src/ir/lexical.py`): *tokenização* (divisão nos espaços, mantendo só os caracteres alfanuméricos de cada palavra), *minúsculas*, *remoção de stopwords* (lista em inglês do NLTK) e *stemming* de Porter. Cada texto vira um dicionário de frequências de termos. A lematização (WordNet) está implementada, mas não foi avaliada nem usada.

A tokenização remove a pontuação dentro das palavras, o que tem um efeito importante neste corpus: termos com hífen ou barra viram um único termo (`meta-analysis` → `metaanalysis`, `shelf-life` → `shelflif`). Uma consulta escrita com espaço não casa com essas formas; esse efeito aparece na análise por consulta e no reranking. Outra limitação: pontuação isolada (como um "-" entre espaços) gera um termo vazio, presente em 1.513 documentos.

As quatro combinações de remoção de stopwords e stemming foram comparadas no dev (`tune_lexical.py`):

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (2.2fr, 1fr, 1fr, 1fr, 1fr),
      align: (left, right, right, right, right),
      table.header([*Stopwords / stemming*], [*Vocabulário*], [*Postings*], [*Termos por doc.*], [*NDCG\@10 dev*]),
      [Mantidas / sem], [36.477], [465.539], [233,8], [0,2655],
      [Removidas / sem], [36.351], [372.335], [155,0], [0,2713],
      [Mantidas / com], [29.037], [443.244], [233,8], [0,2876],
      [*Removidas / com*], [*28.942*], [*350.458*], [*155,0*], [*0,2906*],
    )
  },
  caption: [Pipelines de pré-processamento: efeito na coleção e NDCG\@10 no dev (BM25 com $k_1 = "1,2"$ e $b = "0,75"$).],
) <tab-preproc>

O stemming é a etapa de maior efeito: reduz o vocabulário em 20% e aumenta o NDCG\@10 em 0,022. A remoção de stopwords quase não muda o vocabulário (126 termos), mas reduz os postings em 20% e o tamanho médio dos documentos em 34%, com ganho pequeno de NDCG\@10, já que o IDF do BM25 dá peso baixo a termos muito frequentes. Foi escolhido o pipeline completo (stopwords + stemming), o melhor e o mais compacto. As consultas são curtas (2,6 termos em média após o pré-processamento), então a perda de um único termo afeta muito a busca.

Os modelos neurais recebem o texto bruto, porque usam o próprio tokenizador de subpalavras. O dicionário da correção ortográfica usa os termos antes do stemming e da remoção de stopwords.
