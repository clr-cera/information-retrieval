== Índice invertido

O índice invertido foi implementado do zero na classe `PostingList` (`src/ir/lexical.py`), apenas com dicionários do Python. Ele guarda: o dicionário de termos, com a posting list de cada termo como `{doc_id: tf}`; o número de documentos que contêm cada termo ($n_t$); o tamanho de cada documento ($|d|$, em termos); e a soma dos tamanhos, de onde vêm $N$ e $"avgdl"$ em tempo constante. Dicionários dão acesso em tempo constante ao termo e ao documento; as posting lists não precisam de ordenação, porque o ranqueamento não intersecta listas.

A construção faz uma única passagem pela coleção: cada documento é pré-processado, e cada par (termo, frequência) atualiza de uma vez a posting list, o $n_t$, o tamanho do documento e a soma dos tamanhos. Na consulta, o BM25 é calculado *termo a termo, com acumuladores*: para cada termo da consulta presente no vocabulário, só a sua posting list é percorrida, e a contribuição de cada documento é somada ao seu acumulador. Documentos sem nenhum termo da consulta nunca são acessados.

Uma primeira versão (herdada do TP1) copiava os dicionários de $n_t$ e de tamanhos e somava todos os tamanhos a cada consulta, o que percorria a coleção inteira. A versão final lê as estatísticas diretamente do índice; os rankings das duas versões são idênticos em todas as consultas de dev e test, e um teste automatizado falha se a consulta voltar a copiar as estatísticas.

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

Quase todo o tempo de construção é pré-processamento (5,5 s, contra 0,27 s de inserção, em medição separada). As posting lists têm tamanho muito desigual: 57,9% dos termos aparecem em um único documento, e a maior lista (`studi`) cobre 2.358 documentos. Como só documentos com algum termo da consulta são recuperados, o ranking lexical tem menos de 100 documentos em 134 das 323 consultas do test, e 16 consultas não recuperam nenhum (todos os seus termos estão fora do vocabulário).
