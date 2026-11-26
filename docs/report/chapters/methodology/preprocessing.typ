== Pré-processamento

Cada documento é representado por título e texto. No modelo lexical (BIM25), documentos e consultas passam pelo mesmo pré-processamento, feito com a biblioteca python NLTK e reaproveitado do TP1 (`src/ir/lexical.py`):

- *Tokenização* - Divisão nos espaços, mantendo só os caracteres alfanuméricos de cada palavra 
- *Normalização* - Transformar todas as letras em minúsculas
- *Remoção de stopwords* - Usa lista em inglês do NLTK
- *Stemming* - Radicalização

Cada texto vira um dicionário de frequências de termos.

Como a pontuação dentro das palavras é removida, termos com hífen ou barra viram um único termo (`meta-analysis` → `metaanalysis`, `shelf-life` → `shelflif`), e escritas sem pontuação prejudicam a recuperação do documento ou análise da consulta. Isso será evidente nas análises.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (2.2fr, 1fr, 1fr, 1fr, 1fr),
      align: (left, right, right, right, right),
      table.header([*Stopwords / stemming*], [*Vocabulário*], [*Postings*], [*Termos por doc.*], [*NDCG\@10 dev*]),
      [Não Removidas / sem], [36.477], [465.539], [233,8], [0,2655],
      [Removidas / sem], [36.351], [372.335], [155,0], [0,2713],
      [Não Removidas / com], [29.037], [443.244], [233,8], [0,2876],
      [*Removidas / com*], [*28.942*], [*350.458*], [*155,0*], [*0,2906*],
    )
  },
  caption: [Pipelines de pré-processamento no dev (BM25 com $k_1 = "1,2"$ e $b = "0,75"$).],
) <tab-preproc>

O stemming tem o maior efeito: reduz o vocabulário em cerca de 20% e aumenta o NDCG\@10. A remoção de stopwords reduz os postings em 20%, mas o ganho em NDCG\@10 é pequeno em razão do IDF, que dá peso baixo a termos muito frequentes (stopwords são parte desses termos). 

Foi escolhida a implementação de remoção de stopwords e stemming. Os modelos neurais recebem o texto bruto, porque dependem do contexto da frase (as palavras têm que estar inteiras). O dicionário da correção ortográfica usa os termos antes do stemming e da remoção de stopwords.
