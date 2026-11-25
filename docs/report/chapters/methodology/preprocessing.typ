== Pré-processamento

Cada documento é representado por título + texto em todos os sistemas. No lexical, documentos e consultas passam pelo mesmo pré-processamento, feito com o NLTK 3.10.3 e reaproveitado do TP1 (`src/ir/lexical.py`): *tokenização* (divisão nos espaços, mantendo só os caracteres alfanuméricos de cada palavra), *minúsculas*, *remoção de stopwords* (lista em inglês do NLTK) e *stemming* de Porter. Cada texto vira um dicionário de frequências de termos. A lematização (WordNet) está implementada, mas não foi avaliada nem usada.

Como a pontuação dentro das palavras é removida, termos com hífen ou barra viram um único termo (`meta-analysis` → `metaanalysis`, `shelf-life` → `shelflif`), que não casa com a consulta escrita com espaço; esse efeito reaparece nas análises. Pontuação isolada (um "-" entre espaços) gera um termo vazio, presente em 1.513 documentos.

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

O stemming tem o maior efeito: reduz o vocabulário em 20% e aumenta o NDCG\@10 em 0,022. A remoção de stopwords reduz os postings em 20%, com ganho pequeno, já que o IDF dá peso baixo a termos muito frequentes. Foi escolhido o pipeline completo, o melhor e o mais compacto. Os modelos neurais recebem o texto bruto, porque usam o próprio tokenizador de subpalavras, e o dicionário da correção ortográfica usa os termos antes do stemming e da remoção de stopwords.
