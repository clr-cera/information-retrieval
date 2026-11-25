== Tempos de execução

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (2.2fr, 1fr, 1.4fr),
      align: (left, right, left),
      table.header([*Etapa*], [*Tempo*], [*Quando ocorre*]),
      [Construção do índice invertido], [7,3 s], [uma vez],
      [Embeddings dos 3.633 documentos], [109,7 s], [uma vez],
      [Consulta lexical (BM25)], [0,9 ms], [por consulta],
      [Consulta semântica (embedding da consulta + produto)], [158 ms], [por consulta],
      [Fusão RRF], [0,07 ms], [por consulta],
      [Reranking dos 50 candidatos], [4,09 s], [por consulta],
      [Geração sem RAG (condição A)], [61 s], [por pergunta],
      [Geração com RAG (condição B)], [235 s], [por pergunta],
    )
  },
  caption: [Tempos médios no conjunto test, em CPU (AMD Ryzen 7 5700U, 14 GB de RAM, sem GPU).],
) <tab-times>

A recuperação híbrida completa custa cerca de 0,16 s por consulta, dominada pela geração do embedding da consulta; o BM25 e a fusão são desprezíveis. O reranking multiplica esse custo por cerca de 25, porque exige 50 passadas pelo cross-encoder. A geração é a etapa mais lenta de todas: a LLM roda em CPU e raciocina antes de responder. Com RAG, o prompt passa de 53 para 2.294 tokens em média, e o modelo gera o dobro de tokens (1.128 contra 578, somando raciocínio e resposta), o que explica o tempo quase 4 vezes maior.
