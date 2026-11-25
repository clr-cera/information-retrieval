"""Analysis of the cross-encoder reranking (requirement 10).

Compares the hybrid ranking (before) with the reranked ranking (after) on the test split, using
the final result files. It selects:
- the 2 queries with the largest NDCG@10 gain after reranking;
- 1 query with little or no change (smallest absolute difference among the queries whose
  hybrid NDCG@10 is greater than zero);
- 1 query where the reranking made NDCG@10 worse (largest loss).

For each query it lists the documents of the top-10 after reranking and the relevant documents
that were in the hybrid top-10, with the position before and after, the cross-encoder score,
the relevance grade, whether the (query, document) pair is longer than the cross-encoder limit,
and the title. The output goes to result/tp2/reranking_analysis.md.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from transformers import AutoTokenizer

from ir.data import (
    HYBRID_RESULTS_PATH,
    METRICS_PER_QUERY_PATH,
    RERANK_DEPTH,
    RERANKING_RESULTS_PATH,
    RESULTS_DIR,
    load_experiment_config,
    load_split,
)

ANALYSIS_PATH = RESULTS_DIR / "reranking_analysis.md"
TOP_K = 10
TITLE_LENGTH = 80


def read_ndcg(path: Path) -> dict[str, dict[str, float]]:
    ndcg: dict[str, dict[str, float]] = {}
    with path.open(encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            if row["model"] not in ndcg:
                ndcg[row["model"]] = {}
            ndcg[row["model"]][row["query_id"]] = float(row["NDCG10"])
    return ndcg


def read_rankings(path: Path) -> dict[str, list[tuple[str, float]]]:
    rows: dict[str, list[tuple[int, str, float]]] = {}
    with path.open(encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            if row["query_id"] not in rows:
                rows[row["query_id"]] = []
            rows[row["query_id"]].append((int(row["rank"]), row["doc_id"], float(row["score"])))

    rankings: dict[str, list[tuple[str, float]]] = {}
    for query_id, ranked in rows.items():
        ranked.sort()
        rankings[query_id] = []
        for _, doc_id, score in ranked:
            rankings[query_id].append((doc_id, score))
    return rankings


def position_of(ranking: list[tuple[str, float]], doc_id: str) -> int | None:
    position = 0
    for ranked_doc_id, _ in ranking:
        position += 1
        if ranked_doc_id == doc_id:
            return position
    return None


def format_number(value: float) -> str:
    return f"{value:.4f}".replace(".", ",")


def select_cases(differences: dict[str, float], hybrid_ndcg: dict[str, float]) -> list[tuple[str, str]]:
    """Return [(label, query_id)] for the 4 cases required by the assignment."""
    by_gain = sorted(differences.items(), key=lambda item: (-item[1], item[0]))
    cases = [("maior ganho", by_gain[0][0]), ("segundo maior ganho", by_gain[1][0])]

    candidates = []
    for query_id, difference in differences.items():
        if hybrid_ndcg[query_id] > 0:
            candidates.append((abs(difference), query_id))
    candidates.sort()
    cases.append(("pouca ou nenhuma alteração", candidates[0][1]))

    by_loss = sorted(differences.items(), key=lambda item: (item[1], item[0]))
    cases.append(("maior piora", by_loss[0][0]))
    return cases


def describe_case(label, query_id, split, hybrid, reranked, ndcg, tokenizer, max_length) -> list[str]:
    question = split.queries[query_id].text
    qrels = split.qrels_by_query[query_id]
    hybrid_ranking = hybrid[query_id]
    reranked_ranking = reranked[query_id]

    relevant_count = 0
    for grade in qrels.values():
        if grade > 0:
            relevant_count += 1

    lines = [f"## {label}: {query_id} — \"{question}\"", ""]
    lines.append(f"- NDCG@10: híbrido {format_number(ndcg['hybrid'][query_id])}, "
                 f"com reranking {format_number(ndcg['reranking'][query_id])}; "
                 f"relevantes nos qrels: {relevant_count}")

    relevant_in_candidates = 0
    for doc_id, _ in hybrid_ranking[:RERANK_DEPTH]:
        if qrels.get(doc_id, 0) > 0:
            relevant_in_candidates += 1
    lines.append(f"- Relevantes entre os {RERANK_DEPTH} candidatos reordenados: {relevant_in_candidates}")
    lines.append("")

    # Documents to show: the top-10 after reranking and the relevant ones that left the top-10.
    shown = []
    for doc_id, _ in reranked_ranking[:TOP_K]:
        shown.append(doc_id)
    for doc_id, _ in hybrid_ranking[:TOP_K]:
        if doc_id not in shown and qrels.get(doc_id, 0) > 0:
            shown.append(doc_id)

    lines.append("| Documento | Grau | Pos. híbrido | Pos. reranking | Score cross-encoder | Par > 512 tokens | Título |")
    lines.append("|---|---|---|---|---|---|---|")
    for doc_id in shown:
        before = position_of(hybrid_ranking, doc_id)
        after = position_of(reranked_ranking, doc_id)
        score = None
        for ranked_doc_id, ranked_score in reranked_ranking:
            if ranked_doc_id == doc_id:
                score = ranked_score
                break
        score_text = format_number(score) if score is not None and after is not None and after <= RERANK_DEPTH else "—"

        document = split.documents[doc_id]
        pair_length = len(tokenizer(question, document.searchable_text, truncation=False)["input_ids"])
        truncated = "sim" if pair_length > max_length else "não"
        title = document.title or document.text
        if len(title) > TITLE_LENGTH:
            title = title[: TITLE_LENGTH - 3] + "..."
        title = title.replace("|", "/")

        before_text = str(before) if before is not None else ">100"
        after_text = str(after) if after is not None else ">100"
        lines.append(f"| {doc_id} | {qrels.get(doc_id, 0)} | {before_text} | {after_text} | {score_text} "
                     f"| {truncated} | {title} |")
    lines.append("")
    return lines


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze the cross-encoder reranking on the test split.")
    parser.parse_args()

    selected = load_experiment_config()["selected"]
    split = load_split("test")
    ndcg = read_ndcg(METRICS_PER_QUERY_PATH)
    hybrid = read_rankings(HYBRID_RESULTS_PATH)
    reranked = read_rankings(RERANKING_RESULTS_PATH)

    tokenizer = AutoTokenizer.from_pretrained(selected["reranker_model"])
    max_length = 512

    differences = {}
    changed_top10 = 0
    for query_id in split.queries:
        differences[query_id] = ndcg["reranking"][query_id] - ndcg["hybrid"][query_id]
        before = [doc_id for doc_id, _ in hybrid[query_id][:TOP_K]]
        after = [doc_id for doc_id, _ in reranked[query_id][:TOP_K]]
        if before != after:
            changed_top10 += 1

    gains = 0
    losses = 0
    for difference in differences.values():
        if difference > 0:
            gains += 1
        elif difference < 0:
            losses += 1

    lines = ["# Análise do reranking", ""]
    lines.append(f"- Consultas: {len(differences)}; NDCG@10 melhorou em {gains}, piorou em {losses}, "
                 f"não mudou em {len(differences) - gains - losses}")
    lines.append(f"- Consultas em que o top-10 mudou (ordem ou conteúdo): {changed_top10}")
    lines.append("")

    for label, query_id in select_cases(differences, ndcg["hybrid"]):
        lines.extend(describe_case(label, query_id, split, hybrid, reranked, ndcg, tokenizer, max_length))

    text = "\n".join(lines) + "\n"
    ANALYSIS_PATH.write_text(text, encoding="utf-8")
    print(text)
    print(f"Analysis written to {ANALYSIS_PATH}")


if __name__ == "__main__":
    main()
