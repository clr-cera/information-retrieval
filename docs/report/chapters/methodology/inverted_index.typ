== Índice invertido

O índice foi implementado manualmente na classe `PostingList` (`src/ir/lexical.py`), só com dicionários do Python. Ele guarda a posting list de cada termo (`{doc_id: tf}`), o número de documentos que contêm cada termo ($n_t$), o tamanho de cada documento ($|d|$) e a soma dos tamanhos, de onde vêm $N$ e $"avgdl"$. A construção das posting lists é feita com uma varredura única na coleção. Na consulta lexical com BM25, só as posting lists dos termos da consulta são percorridas (intersecção entre consulta e documentos).

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (2.4fr, 1fr),
      align: (left, right),
      table.header([*Métrica (test)*], [*Valor*]),
      [Termos no vocabulário], [28.942],
      [Total de postings], [350.458],
      [Tempo de construção do índice (inclui o pré-processamento)], [7,32 s],
      [Tempo médio por consulta (323 consultas)], [0,90 ms]
    )
  },
  caption: [Estatísticas do índice invertido. Uso de CPU AMD Ryzen 7 5700U.],
) <tab-index-stats>

Quase todo o tempo de construção é pré-processamento (5.5 s de pré-processamento, 0.27 s de inserção).
