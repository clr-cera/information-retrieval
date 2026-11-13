# TP2 Experiment Protocol

## Dataset and representation

- Dataset: NFCorpus, official BEIR distribution (`corpus.jsonl`, `queries.jsonl`, `qrels/{train,dev,test}.tsv`).
- Query set per split: only queries that have judgments in that split.
- Document representation for every system: `title + " " + text`.
- Identifiers from BEIR are kept as strings.
- The loader downloads to `data/nfcorpus` by default; override with `NFCORPUS_DIR`.
- Generated data, embeddings and result files are not committed.

## Split usage

- `train`: available but not used for tuning unless explicitly justified.
- `dev`: the only split used to choose preprocessing, lexical model, BM25 parameters (if changed), typo-correction thresholds, embedding model, RRF `k`, reranker model and any other configuration.
- `test`: reserved for the final evaluation only.

No decision may be based on test-set metrics. This includes query rewriting, model selection, parameter selection, ranking adjustments and example selection. The only pre-fixed test choice is the RAG query sample required by the specification.

## Fixed protocol values

- Evaluation metrics: Precision@10, Recall@10, AP@10, NDCG@10.
- Relevant for P@10, R@10 and AP@10: grade greater than zero.
- AP@10: truncated at rank 10, divided by the total number of relevant documents in the qrels.
- NDCG@10: linear gain, ideal ranking built from all judgments of the query.
- Per-query metrics are preserved in `metrics_per_query.csv`; reported means are computed over all judged queries of the split.
- Ranking files contain the first 100 documents per query.
- RRF fuses the first 100 documents of each system, with `k` selected on dev from `{10, 60, 100}` by mean NDCG@10.
- Reranking reorders the first 50 documents of the hybrid ranking only; documents below rank 50 keep their relative hybrid order.
- RAG uses the 10 test queries reproduced with seed 42 and listed in `config/tp2_experiment.json`.

## Reproducibility

- All random operations use an explicit seed.
- LLM temperature is 0 (or the lowest supported value) and a fixed seed is used when available.
- The selected configuration is recorded in `config/tp2_experiment.json` and frozen before the final test run.
- Final result CSVs are produced by scripts, not manually copied from notebooks.
