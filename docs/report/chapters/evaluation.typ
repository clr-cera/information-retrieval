== Conjunto de dados e splits

O trabalho usa o NFCorpus na versão do benchmark BEIR: 3.633 documentos da área de nutrição e saúde (quase todos resumos de artigos científicos) e os arquivos padronizados `corpus.jsonl`, `queries.jsonl` e `qrels/{train,dev,test}.tsv`. Como o servidor oficial do BEIR estava inacessível, os arquivos foram obtidos da cópia do BEIR no Hugging Face (`BeIR/nfcorpus` e `BeIR/nfcorpus-qrels`, com revisões fixadas), indicada no enunciado. A conferência das contagens e da amostra do RAG confirma que o conteúdo é o mesmo do arquivo oficial.

O `queries.jsonl` contém as 3.237 consultas de todos os splits; as consultas de cada split são somente as que têm julgamentos no qrels correspondente.

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
  caption: [Splits do NFCorpus. Documentos fora dos qrels são considerados não relevantes (grau 0).],
) <tab-splits>

Nos splits dev e test, há dois graus de relevância: 2 (cerca de 5% dos julgamentos) e 1. O conjunto dev foi usado para todas as escolhas de configuração, e o test, apenas para a avaliação final. O train não foi usado.

== Métricas

Os sistemas são avaliados com Precision\@10, Recall\@10, MAP\@10 e NDCG\@10, implementadas pelo grupo (`src/ir/metrics.py`) e calculadas para cada consulta. Seja $"rel"$ o conjunto de documentos com grau maior que zero e $R = |"rel"|$:

- *P\@10* e *R\@10*: número de relevantes entre os 10 primeiros, dividido por 10 e por $R$, respectivamente. O denominador de R\@10 é o total de relevantes da consulta nos qrels.
- *AP\@10*: $1\/R sum_(i <= 10) P\@i dot bb(1)[d_i in "rel"]$, isto é, a soma de P\@$i$ nas posições com documento relevante, dividida pelo total de relevantes da consulta (convenção do `trec_eval` e do `ir_measures`). O *MAP\@10* é a média da AP\@10 sobre as consultas.
- *NDCG\@10*: $"DCG"\@10 \/ "IDCG"\@10$, com $"DCG"\@10 = sum_(i <= 10) g_i \/ log_2(i + 1)$ e ganho linear ($g_i$ é o grau de relevância). O ranking ideal é formado a partir de *todos* os julgamentos da consulta, e não só dos documentos recuperados.

Para P\@10, R\@10 e AP\@10, é relevante todo documento com grau maior que zero; o NDCG\@10 preserva os graus. Na etapa de RAG, serão usadas também P\@5, R\@5 e Hit\@5 (1 se ao menos um relevante está entre os 5 primeiros).

As médias são calculadas sobre todas as 323 consultas do test. Uma consulta para a qual o sistema não recupera nenhum documento conta com valor zero em todas as métricas. As métricas por consulta de todos os sistemas estão em `metrics_per_query.csv`, e a média da coluna `AP10` coincide com o MAP\@10 reportado.

A implementação foi conferida com a biblioteca `ir_measures` de duas formas: em rankings sintéticos de todas as consultas do test, e nos rankings finais dos quatro sistemas, consulta a consulta. A maior diferença encontrada foi de $3 dot 10^(-16)$, isto é, apenas arredondamento numérico.

== Modelos e parâmetros

Configuração final, toda escolhida no dev: pré-processamento com remoção de stopwords e stemming de Porter; BM25 com $k_1 = "1,2"$ e $b = "0,75"$; correção ortográfica com bigramas, Jaccard $>= "0,2"$ e distância $<= 2$; bi-encoder `all-MiniLM-L6-v2`; RRF com $k = 10$ sobre os 100 primeiros de cada sistema; cross-encoder `ms-marco-MiniLM-L6-v2` nos 50 primeiros do híbrido; e LLM Qwen3 4B com temperatura 0 e os 5 primeiros documentos como contexto. Os detalhes de cada componente estão nas seções da metodologia.

== Ambiente computacional

Todos os experimentos foram executados em um notebook com processador AMD Ryzen 7 5700U (8 núcleos, 16 threads) e 14 GB de RAM, em Linux, *sem GPU*: os modelos neurais rodaram em CPU (8 threads do PyTorch). O código foi escrito em Python 3.13, com NLTK 3.10.3, NumPy 2.5.3, PyTorch 2.15.0, Sentence Transformers 6.3.0, Transformers 5.23.0, pandas 3.1.0 e ir-measures 0.4.3. As versões exatas de todas as dependências estão no arquivo `uv.lock`.

== Protocolo experimental

As configurações foram escolhidas exclusivamente no conjunto dev, cada uma pelo maior NDCG\@10 médio, com uma exceção justificada na seção de busca lexical:

+ pré-processamento e parâmetros do BM25 (adotados os valores usuais, porque a vantagem do melhor valor da grade era menor que a variação causada por empates de score);
+ limiares da correção ortográfica, pela fração de 200 erros simulados corrigidos exatamente;
+ modelo de embeddings, entre dois bi-encoders;
+ $k$ do RRF, entre 10, 60 e 100;
+ modelo de reranking, entre dois cross-encoders, sobre o ranking híbrido.

Com a configuração congelada (`config/tp2_experiment.json`), cada sistema foi executado uma única vez sobre as 323 consultas do test, que são as mesmas para todos os sistemas. *Os qrels do test não foram usados para modificar consultas, escolher parâmetros, alterar rankings ou selecionar exemplos*, com as duas exceções previstas no enunciado: a escolha das consultas do experimento de erros, que exige NDCG\@10 original maior que zero, e a amostra fixa das 10 consultas do RAG, sorteada com seed 42. Todos os sorteios usam seed fixa, e os resultados são gerados por scripts, não por notebooks.
