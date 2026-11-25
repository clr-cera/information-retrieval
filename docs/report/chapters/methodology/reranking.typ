== Reranking

O ranking híbrido é o recuperador inicial. Os seus 50 primeiros documentos são reordenados por um *cross-encoder*, um modelo que recebe a consulta e o documento juntos (`[CLS] consulta [SEP] documento [SEP]`) e devolve um score de relevância para o par. Ao contrário do bi-encoder, que gera os vetores de consulta e documento separadamente, o cross-encoder relaciona cada palavra da consulta com cada palavra do documento, o que o torna mais preciso, porém mais caro: cada par exige uma passada pelo modelo, e nada pode ser calculado antes da consulta. Por isso ele só é aplicado aos 50 candidatos. Os documentos abaixo da posição 50 continuam depois deles, na mesma ordem relativa do híbrido, de modo que o ranking continua completo para as métricas. A implementação está na classe `CrossEncoderReranker` (`src/ir/neural.py`), usando a classe `CrossEncoder` do Sentence Transformers.

O modelo foi escolhido no dev (script `tune_reranker.py`), entre dois cross-encoders pré-treinados no MS MARCO, um conjunto de consultas reais de um buscador com trechos de páginas julgados relevantes:

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1.6fr, auto, auto, auto),
      align: (left, right, right, right),
      table.header([*Modelo*], [*Camadas*], [*NDCG\@10 (dev)*], [*Tempo por consulta*]),
      [Híbrido, sem reranking], [—], [0,3299], [—],
      [`cross-encoder/ms-marco-MiniLM-L6-v2`], [6], [*0,3310*], [3,72 s],
      [`cross-encoder/ms-marco-TinyBERT-L2-v2`], [2], [0,3237], [0,36 s],
    )
  },
  caption: [Escolha do cross-encoder no conjunto dev, reordenando os 50 primeiros do híbrido, em CPU.],
) <tab-rerank-dev>

Foi escolhido o `ms-marco-MiniLM-L6-v2` (revisão `233902d2` do Hugging Face), o de maior NDCG\@10. O TinyBERT é 10 vezes mais rápido, mas *piora* o híbrido no dev. Vale notar que, no dev, o ganho do MiniLM sobre o híbrido é pequeno (+0,0011).

O comprimento máximo de entrada do cross-encoder é de *512 tokens*, para o par consulta + documento. Pares mais longos são truncados (o fim do documento é descartado). No test, 1.426 dos 16.150 pares avaliados (8,8%) passam desse limite, uma fração bem menor que a do bi-encoder (78,8% dos documentos), porque o limite é o dobro.
