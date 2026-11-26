== Dataset, splits e qrels

O trabalho usa o NFCorpus do BEIR, com os arquivos `corpus.jsonl`, `queries.jsonl` e `qrels/{train,dev,test}.tsv`. Como o servidor oficial do BEIR estava inacessível, os arquivos foram obtidos da cópia no Hugging Face indicada na especificação do trabalho (`BeIR/nfcorpus` e `BeIR/nfcorpus-qrels`).

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (auto, auto, auto, 1fr, auto),
      align: (left, right, right, right, left),
      table.header([*Split*], [*Consultas*], [*Julgamentos*], [*Relevantes por consulta*], [*Graus*]),
      [train], [2.590], [110.575], [42,7 em média], [1],
      [dev], [324], [11.385], [35,1 em média (1 a 919)], [1 e 2],
      [test], [323], [12.334], [38,2 em média (1 a 475)], [1 e 2],
    )
  },
  caption: [Conjuntos do NFCorpus (3.633 documentos).],
) <tab-splits>

O dev foi usado para todas as escolhas de configuração, e o test, só para a avaliação final; o train não foi usado.

== Métricas

As métricas foram implementadas em (`src/ir/metrics.py`) e calculadas por consulta. Seja $"rel"$ o conjunto de documentos com grau maior que zero e $R = |"rel"|$:

- *P\@10*: Número de relevantes entre os 10 primeiros, dividido por 10
- *R\@10* - Número de relevantes entre os 10 primeiros, dividido por $R$ (total de documentos relevantes).
- *AP\@10*: $1/R sum_(i=1)^10 P\@i", "d_i in "rel"$ - O *MAP\@10* é a média da AP\@10 sobre as consultas.
- *NDCG\@10*: $("DCG"\@10)/ ("IDCG"\@10)$, com $"DCG"\@10 = sum_(i = 1)^10 g_i / (log_2(i + 1))$ e ganho linear ($g_i$ é o grau).

No RAG, usam-se também P\@5, R\@5 e Hit\@5 (1 se ao menos um relevante está entre os 5 primeiros). As médias cobrem toda sas consultas do test, e uma consulta sem documentos recuperados conta como zero. Os valores por consulta estão no `metrics_per_query.csv`, cuja média da coluna `AP10` é o MAP\@10 avaliado. A implementação foi conferida com o `ir_measures` nos rankings finais dos quatro sistemas, consulta a consulta, com diferença máxima de $3 dot 10^(-16)$ (ou seja, resultados satisfatórios).

== Modelos, parâmetros e ambiente computacional

Configuração final, toda escolhida no dev:

- Pré-processamento com remoção de stopwords e stemming de Porter;
- BM25 com $k_1 = "1,2"$ e $b = "0,75"$;
- Correção ortográfica com bigramas, Jaccard $>= "0,2"$ e distância $<= 2$;
- Bi-encoder `all-MiniLM-L6-v2`;
- RRF com $k = 10$ sobre os 100 primeiros de cada sistema;
- Cross-encoder `ms-marco-MiniLM-L6-v2` nos 50 primeiros do híbrido;
- LLM Qwen3 4B com temperatura 0, recebendo os 5 primeiros documentos.

Os experimentos rodaram em um notebook com AMD Ryzen 7 5700U (8 núcleos) e 14 GB de RAM, em Linux, *sem GPU* (modelos neurais em CPU, com 8 threads). O código usa Python 3.13, NLTK 3.10.3, NumPy 2.5.3, PyTorch 2.15.0, Sentence Transformers 6.3.0, Transformers 5.23.0 e ir-measures 0.4.3; as versões exatas estão no `uv.lock`.

== Protocolo experimental

As configurações foram escolhidas só no dev:

- Pré-processamento, modelo de embeddings (entre dois bi-encoders), $k$ do RRF (entre 10, 60 e 100) e cross-encoder (entre dois): pelo maior NDCG\@10 médio;
- Parâmetros da correção ortográfica: pela taxa de correção exata de 200 erros simulados;
- BM25: foram escolhidos os fatores com maior desempenho ($k=1.2$ e $b=0.75$)

Com a configuração congelada (`config/tp2_experiment.json`), cada sistema foi executado uma única vez sobre todas as consultas do test. Os qrels do test não foram usados para modificar consultas, escolher parâmetros, alterar rankings ou selecionar exemplos.

Os sorteios usam seed fixa, e todos os resultados são gerados por scripts.
