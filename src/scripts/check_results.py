"""Check the standardized result files required by the assignment (requirement 15).

For each file it checks that it exists and has the required columns, and:
- ranking files: at most 100 documents per query, ranks 1, 2, 3... without gaps, every test
  query present (an empty ranking is allowed only for the lexical system), and the
  relevance column equal to the qrels;
- metrics_per_query.csv: the 4 systems with every test query, and the mean of AP10 equal to
  the MAP@10 reported in retrieval_summary.json;
- typo_experiment.csv: 10 queries;
- rag_experiment.csv: 10 queries x 2 conditions, and whether the human scores were filled.
"""

from __future__ import annotations

import csv
import json

from ir.data import (
    HYBRID_RESULTS_PATH,
    LEXICAL_RESULTS_PATH,
    METRICS_PER_QUERY_PATH,
    RAG_EXPERIMENT_PATH,
    RERANKING_RESULTS_PATH,
    RESULTS_DIR,
    SEMANTIC_RESULTS_PATH,
    TYPO_EXPERIMENT_PATH,
    load_split,
)

RANKING_COLUMNS = ["query_id", "doc_id", "rank", "score", "relevance"]
METRICS_COLUMNS = ["query_id", "model", "P10", "R10", "AP10", "NDCG10"]
TYPO_COLUMNS = ["query_id", "query_original", "query_erro", "query_corrigida", "tipo_erro",
                "NDCG10_original", "NDCG10_erro", "NDCG10_corrigida"]
RAG_COLUMNS = ["query_id", "query", "condition", "context_doc_ids", "prompt", "answer",
               "fidelidade", "completude", "utilidade", "rastreabilidade",
               "fidelidade_justificativa", "completude_justificativa",
               "utilidade_justificativa", "rastreabilidade_justificativa"]


def read_csv(path, required_columns, problems):
    if not path.exists():
        problems.append(f"{path.name}: file not found")
        return []
    with path.open(encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        missing = [column for column in required_columns if column not in (reader.fieldnames or [])]
        if missing:
            problems.append(f"{path.name}: missing columns {missing}")
        return list(reader)


def check_ranking_file(path, name, qrels_by_query, problems) -> None:
    rows = read_csv(path, RANKING_COLUMNS, problems)
    ranks_by_query: dict[str, list[int]] = {}
    for row in rows:
        query_id = row["query_id"]
        if query_id not in ranks_by_query:
            ranks_by_query[query_id] = []
        ranks_by_query[query_id].append(int(row["rank"]))
        expected = qrels_by_query.get(query_id, {}).get(row["doc_id"], 0)
        if int(row["relevance"]) != expected:
            problems.append(f"{path.name}: wrong relevance for {query_id} {row['doc_id']}")

    missing_queries = [query_id for query_id in qrels_by_query if query_id not in ranks_by_query]
    if missing_queries and name != "lexical":
        problems.append(f"{path.name}: {len(missing_queries)} queries without ranking")

    short = 0
    for query_id, ranks in ranks_by_query.items():
        if len(ranks) > 100:
            problems.append(f"{path.name}: {query_id} has {len(ranks)} documents (more than 100)")
        if sorted(ranks) != list(range(1, len(ranks) + 1)):
            problems.append(f"{path.name}: {query_id} has gaps in the ranks")
        if len(ranks) < 100:
            short += 1
    print(f"{path.name}: {len(rows)} rows, {len(ranks_by_query)} queries, "
          f"{short} queries with fewer than 100 documents, {len(missing_queries)} without documents")


def main() -> None:
    split = load_split("test")
    qrels_by_query = split.qrels_by_query
    problems: list[str] = []

    rankings = (
        (LEXICAL_RESULTS_PATH, "lexical"),
        (SEMANTIC_RESULTS_PATH, "semantic"),
        (HYBRID_RESULTS_PATH, "hybrid"),
        (RERANKING_RESULTS_PATH, "reranking"),
    )
    for path, name in rankings:
        check_ranking_file(path, name, qrels_by_query, problems)

    metric_rows = read_csv(METRICS_PER_QUERY_PATH, METRICS_COLUMNS, problems)
    summary_path = RESULTS_DIR / "retrieval_summary.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))["aggregated_metrics"]
    for _, model in rankings:
        values = [float(row["AP10"]) for row in metric_rows if row["model"] == model]
        if len(values) != len(qrels_by_query):
            problems.append(f"{METRICS_PER_QUERY_PATH.name}: {model} has {len(values)} queries")
            continue
        mean_ap = sum(values) / len(values)
        difference = abs(mean_ap - summary[model]["AP10"])
        print(f"{METRICS_PER_QUERY_PATH.name}: {model} mean AP10 = {mean_ap:.4f}, "
              f"MAP@10 reported = {summary[model]['AP10']:.4f}")
        if difference > 1e-9:
            problems.append(f"{model}: mean AP10 differs from the reported MAP@10")

    typo_rows = read_csv(TYPO_EXPERIMENT_PATH, TYPO_COLUMNS, problems)
    print(f"{TYPO_EXPERIMENT_PATH.name}: {len(typo_rows)} queries")
    if typo_rows and len(typo_rows) != 10:
        problems.append(f"{TYPO_EXPERIMENT_PATH.name}: expected 10 queries")

    rag_rows = read_csv(RAG_EXPERIMENT_PATH, RAG_COLUMNS, problems)
    if rag_rows:
        conditions = sorted({row["condition"] for row in rag_rows})
        filled = 0
        for row in rag_rows:
            if row["fidelidade"] not in ("", "N/A"):
                filled += 1
        print(f"{RAG_EXPERIMENT_PATH.name}: {len(rag_rows)} rows, conditions {conditions}, "
              f"{filled} rows with human scores")
        if len(rag_rows) != 20:
            problems.append(f"{RAG_EXPERIMENT_PATH.name}: expected 20 rows (10 queries x 2 conditions)")
        if filled < len(rag_rows):
            problems.append(f"{RAG_EXPERIMENT_PATH.name}: human scores not filled yet (run evaluate_rag.py merge)")

    print()
    if problems:
        print("Problems found:")
        for problem in problems:
            print(f"  - {problem}")
        raise SystemExit(1)
    print("All standardized result files are complete.")


if __name__ == "__main__":
    main()
