"""Per-query comparison between the lexical and the semantic systems (requirement 7).

Uses the final result files of the test split:
- results/metrics_per_query.csv (NDCG@10 of each system and query);
- results/results_lexical.csv and results/results_semantic.csv (rankings and scores).

For each query it computes the difference NDCG@10(semantic) - NDCG@10(lexical) and
selects the 3 queries with the largest advantage of each system. For the 6 queries it
collects the evidence needed to explain the difference:

- the query terms after preprocessing and in how many documents each one appears;
- the top-5 of each system, with score, relevance grade and title;
- which query terms each top document contains (and how many times);
- whether the document was truncated by the bi-encoder (more than 256 tokens);
- the position of each top document in the other system's ranking;
- how many relevant documents of the query contain at least one query term.

The output is written to results/lexical_vs_semantic_analysis.md and printed.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from ir.data import (
    LEXICAL_RESULTS_PATH,
    METRICS_PER_QUERY_PATH,
    RESULTS_DIR,
    SEMANTIC_RESULTS_PATH,
    load_experiment_config,
    load_split,
)
from ir.lexical import LexicalIndex, PipelineOptions, get_index_terms_freq

ANALYSIS_PATH = RESULTS_DIR / "lexical_vs_semantic_analysis.md"
QUERIES_PER_SIDE = 3
TOP_K_TO_SHOW = 5
TITLE_LENGTH = 90


def read_ndcg_by_query(path: Path) -> dict[str, dict[str, float]]:
    """Return {model: {query_id: NDCG@10}} from metrics_per_query.csv."""
    ndcg_by_model: dict[str, dict[str, float]] = {}
    with path.open(encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            model = row["model"]
            if model not in ndcg_by_model:
                ndcg_by_model[model] = {}
            ndcg_by_model[model][row["query_id"]] = float(row["NDCG10"])
    return ndcg_by_model


def read_rankings(path: Path) -> dict[str, list[tuple[str, float]]]:
    """Return {query_id: [(doc_id, score), ...]} in rank order from a results_*.csv file."""
    rankings: dict[str, list[tuple[int, str, float]]] = {}
    with path.open(encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            query_id = row["query_id"]
            if query_id not in rankings:
                rankings[query_id] = []
            rankings[query_id].append((int(row["rank"]), row["doc_id"], float(row["score"])))

    ordered: dict[str, list[tuple[str, float]]] = {}
    for query_id, rows in rankings.items():
        rows.sort()
        ordered[query_id] = []
        for _, doc_id, score in rows:
            ordered[query_id].append((doc_id, score))
    return ordered


def position_in(ranking: list[tuple[str, float]], doc_id: str) -> str:
    """Position of a document in a ranking (1-based), or '>100' when it is not there."""
    position = 0
    for ranked_doc_id, _ in ranking:
        position += 1
        if ranked_doc_id == doc_id:
            return str(position)
    return ">100"


def format_number(value: float, decimals: int = 4) -> str:
    return f"{value:.{decimals}f}".replace(".", ",")


def short_title(text: str) -> str:
    text = text.replace("|", "/")
    if len(text) <= TITLE_LENGTH:
        return text
    return text[: TITLE_LENGTH - 3] + "..."


def select_queries(differences: dict[str, float]) -> tuple[list[str], list[str]]:
    """The queries with the largest advantage of the semantic and of the lexical system.

    Ties in the difference are broken by the query identifier, so the selection is deterministic.
    """
    ordered = sorted(differences.items(), key=lambda item: (-item[1], item[0]))
    semantic_side = []
    for query_id, difference in ordered[:QUERIES_PER_SIDE]:
        if difference > 0:
            semantic_side.append(query_id)

    ordered = sorted(differences.items(), key=lambda item: (item[1], item[0]))
    lexical_side = []
    for query_id, difference in ordered[:QUERIES_PER_SIDE]:
        if difference < 0:
            lexical_side.append(query_id)
    return semantic_side, lexical_side


def describe_query(query_id, split, index, pipeline_options, tokenizer, max_tokens, rankings, ndcg) -> list[str]:
    """Build the Markdown lines with the evidence for one query."""
    query_text = split.queries[query_id].text
    qrels = split.qrels_by_query[query_id]
    posting_list = index.posting_list
    query_terms = list(get_index_terms_freq(query_text, pipeline_options))

    relevant_ids = []
    for doc_id, grade in qrels.items():
        if grade > 0:
            relevant_ids.append(doc_id)

    # How many relevant documents contain at least one query term (reachable by BM25).
    reachable = 0
    for doc_id in relevant_ids:
        for term in query_terms:
            if doc_id in posting_list.postings.get(term, {}):
                reachable += 1
                break

    lines = []
    lines.append(f"## {query_id}: \"{query_text}\"")
    lines.append("")
    lines.append(f"- NDCG@10: lexical {format_number(ndcg['lexical'][query_id])}, "
                 f"semântico {format_number(ndcg['semantic'][query_id])}, "
                 f"diferença (semântico − lexical) {format_number(ndcg['semantic'][query_id] - ndcg['lexical'][query_id])}")
    lines.append(f"- Documentos relevantes nos qrels: {len(relevant_ids)}; "
                 f"com pelo menos um termo da consulta: {reachable}")

    term_descriptions = []
    for term in query_terms:
        document_frequency = posting_list.get_document_frequency(term)
        term_descriptions.append(f"`{term}` ({document_frequency} docs)")
    if term_descriptions:
        lines.append("- Termos da consulta no índice: " + ", ".join(term_descriptions))
    else:
        lines.append("- Termos da consulta no índice: nenhum")
    lines.append("")

    for system, other in (("lexical", "semantic"), ("semantic", "lexical")):
        label = "Lexical (BM25)" if system == "lexical" else "Semântico (cosseno)"
        lines.append(f"### Top-{TOP_K_TO_SHOW} {label}")
        lines.append("")
        lines.append("| Pos. | Documento | Score | Grau | Termos da consulta no documento (tf) | Tokens | Pos. no outro | Título |")
        lines.append("|---|---|---|---|---|---|---|---|")

        ranking = rankings[system].get(query_id, [])
        position = 0
        for doc_id, score in ranking[:TOP_K_TO_SHOW]:
            position += 1
            grade = qrels.get(doc_id, 0)

            matched_terms = []
            for term in query_terms:
                term_frequency = posting_list.postings.get(term, {}).get(doc_id, 0)
                if term_frequency > 0:
                    matched_terms.append(f"{term}×{term_frequency}")
            matched_text = ", ".join(matched_terms) if matched_terms else "nenhum"

            token_count = len(tokenizer(split.documents[doc_id].searchable_text, truncation=False)["input_ids"])
            token_text = f"{token_count} (truncado)" if token_count > max_tokens else str(token_count)

            other_position = position_in(rankings[other].get(query_id, []), doc_id)
            title = short_title(split.documents[doc_id].title or split.documents[doc_id].text)
            lines.append(f"| {position} | {doc_id} | {format_number(score)} | {grade} | {matched_text} "
                         f"| {token_text} | {other_position} | {title} |")
        if position == 0:
            lines.append("| — | nenhum documento recuperado | | | | | | |")
        lines.append("")

    return lines


def main() -> None:
    parser = argparse.ArgumentParser(description="Per-query comparison between lexical and semantic retrieval.")
    parser.add_argument("--split", default="test")
    args = parser.parse_args()

    from sentence_transformers import SentenceTransformer

    config = load_experiment_config()
    selected = config["selected"]
    split = load_split(args.split)
    pipeline_options = PipelineOptions[selected["preprocessing"]]
    index = LexicalIndex(split.document_texts, pipeline_options)

    model = SentenceTransformer(selected["embedding_model"], device="cpu")
    tokenizer = model.tokenizer
    max_tokens = model.max_seq_length

    ndcg = read_ndcg_by_query(METRICS_PER_QUERY_PATH)
    rankings = {
        "lexical": read_rankings(LEXICAL_RESULTS_PATH),
        "semantic": read_rankings(SEMANTIC_RESULTS_PATH),
    }

    differences = {}
    for query_id in split.queries:
        differences[query_id] = ndcg["semantic"][query_id] - ndcg["lexical"][query_id]
    semantic_side, lexical_side = select_queries(differences)

    lines = ["# Lexical × semântico: análise por consulta", ""]
    lines.append(f"Consultas do split {args.split}: {len(differences)}. "
                 f"Bi-encoder: `{selected['embedding_model']}` (máximo de {max_tokens} tokens).")
    lines.append("")
    lines.append("# Maior vantagem do sistema semântico")
    lines.append("")
    for query_id in semantic_side:
        lines.extend(describe_query(query_id, split, index, pipeline_options, tokenizer, max_tokens, rankings, ndcg))
    lines.append("# Maior vantagem do sistema lexical")
    lines.append("")
    for query_id in lexical_side:
        lines.extend(describe_query(query_id, split, index, pipeline_options, tokenizer, max_tokens, rankings, ndcg))

    text = "\n".join(lines) + "\n"
    ANALYSIS_PATH.write_text(text, encoding="utf-8")
    print(text)
    print(f"Analysis written to {ANALYSIS_PATH}")


if __name__ == "__main__":
    main()
