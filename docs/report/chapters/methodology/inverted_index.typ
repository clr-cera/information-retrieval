== Índice invertido

O índice foi implementado do zero na classe `PostingList` (`src/ir/lexical.py`), só com dicionários do Python. Ele guarda a posting list de cada termo (`{doc_id: tf}`), o número de documentos que contêm cada termo ($n_t$), o tamanho de cada documento ($|d|$, em termos) e a soma dos tamanhos, de onde vêm $N$ e $"avgdl"$ em tempo constante. A construção faz uma única passagem pela coleção. Na consulta, o BM25 é calculado *termo a termo, com acumuladores*: só as posting lists dos termos da consulta são percorridas, e documentos sem nenhum desses termos nunca são acessados. Um teste automatizado falha se a consulta voltar a percorrer as estatísticas da coleção.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (2.4fr, 1fr),
      align: (left, right),
      table.header([*Estatística (test)*], [*Valor*]),
      [Termos no vocabulário], [28.942],
      [Total de postings], [350.458],
      [Tempo de construção do índice (inclui o pré-processamento)], [7,32 s],
      [Tempo médio por consulta (323 consultas)], [0,90 ms],
      [Postings visitados por consulta (média)], [558 (0,16% do índice)],
    )
  },
  caption: [Estatísticas do índice invertido, em CPU (AMD Ryzen 7 5700U).],
) <tab-index-stats>

Quase todo o tempo de construção é pré-processamento (5,5 s, contra 0,27 s de inserção). Como só documentos com algum termo da consulta são recuperados, o ranking lexical tem menos de 100 documentos em 134 das 323 consultas do test, e 16 consultas não recuperam nenhum.
