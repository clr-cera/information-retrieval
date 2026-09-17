import argparse
import ast
import csv
import re
import sys
from math import log
from pathlib import Path

from ir_datasets import load

REPO_ROOT = Path(__file__).resolve().parent
SRC_DIR = REPO_ROOT / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from document_processor import PipelineOptions, get_index_terms_freq
from main import QUERY_MODIFICATIONS
from posting_list import PostingList

CONFIG_PATTERN = re.compile(
    r"^(?P<pipeline>.+)_(?P<model>Probabilistic|Vectorial)"
    r"(?:_k(?P<k>[\d.]+)_b(?P<b>[\d.]+))?$"
)
MODIFIED_QUERY_SUFFIX = "_mod"


def parse_literal_file(path):
    values = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            query_label, rest = line.split(": ", 1)
            values[query_label.removeprefix("Query ")] = ast.literal_eval(rest)
    return values


def discover_experiments(result_dir):
    experiments = {}
    for path in sorted(result_dir.glob("metrics_*.txt")):
        if path.name.endswith("_aggregated.txt"):
            continue
        identifier = path.name[len("metrics_"):-len(".txt")]
        match = CONFIG_PATTERN.match(identifier)
        if match is None:
            continue
        k = match.group("k")
        b = match.group("b")
        experiments[identifier] = {
            "identifier": identifier,
            "pipeline": match.group("pipeline"),
            "model": match.group("model"),
            "k": float(k) if k else None,
            "b": float(b) if b else None,
            "metrics": parse_literal_file(path),
        }
    return experiments


def attach_rankings(experiments, result_dir):
    for experiment in experiments.values():
        path = result_dir / f"top_10_docs_{experiment['identifier']}.txt"
        experiment["ranking"] = parse_literal_file(path) if path.exists() else {}


def original_query_metrics(experiment):
    return {
        query_id: metrics
        for query_id, metrics in experiment["metrics"].items()
        if not query_id.endswith(MODIFIED_QUERY_SUFFIX)
    }


def mean_metrics(experiment):
    values = list(original_query_metrics(experiment).values())
    if not values:
        return None
    return {
        key: sum(value[key] for value in values) / len(values)
        for key in values[0]
    }


def best_experiment(experiments, model, pipeline=None):
    candidates = [
        experiment
        for experiment in experiments.values()
        if experiment["model"] == model
        and (pipeline is None or experiment["pipeline"] == pipeline)
        and mean_metrics(experiment) is not None
    ]
    if not candidates:
        return None
    return max(candidates, key=lambda experiment: mean_metrics(experiment)["map"])


def query_sort_key(query_id):
    try:
        return (0, int(query_id), "")
    except ValueError:
        return (1, 0, query_id)


def format_ranking(ranking_entry, limit=10, with_scores=False):
    if not ranking_entry:
        return "-"
    parts = []
    for doc_id, score, relevance in ranking_entry[:limit]:
        marker = "[R]" if relevance else "[ ]"
        if with_scores:
            parts.append(f"{doc_id}{marker}({score:.2f})")
        else:
            parts.append(f"{doc_id}{marker}")
    return " ".join(parts)


def write_lines(path, lines):
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_aggregated_csv(experiments, path):
    fieldnames = ["identifier", "pipeline", "model", "k", "b", "precision@10", "recall@10", "map", "queries"]
    rows = []
    for experiment in experiments.values():
        aggregate = mean_metrics(experiment)
        if aggregate is None:
            continue
        rows.append({
            "identifier": experiment["identifier"],
            "pipeline": experiment["pipeline"],
            "model": experiment["model"],
            "k": experiment["k"],
            "b": experiment["b"],
            "precision@10": round(aggregate["precision@10"], 4),
            "recall@10": round(aggregate["recall@10"], 4),
            "map": round(aggregate["map"], 4),
            "queries": len(original_query_metrics(experiment)),
        })
    rows.sort(key=lambda row: (row["pipeline"], row["model"], row["k"] or 0, row["b"] or 0))
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return rows


def build_comparison_rows(bm25, vectorial):
    shared_queries = set(original_query_metrics(bm25)) & set(original_query_metrics(vectorial))
    rows = []
    for query_id in shared_queries:
        bm25_metrics = bm25["metrics"][query_id]
        vectorial_metrics = vectorial["metrics"][query_id]
        rows.append({
            "query_id": query_id,
            "bm25_map": bm25_metrics["map"],
            "vectorial_map": vectorial_metrics["map"],
            "delta_map": bm25_metrics["map"] - vectorial_metrics["map"],
            "bm25_precision@10": bm25_metrics["precision@10"],
            "vectorial_precision@10": vectorial_metrics["precision@10"],
            "delta_precision@10": bm25_metrics["precision@10"] - vectorial_metrics["precision@10"],
            "bm25_recall@10": bm25_metrics["recall@10"],
            "vectorial_recall@10": vectorial_metrics["recall@10"],
            "delta_recall@10": bm25_metrics["recall@10"] - vectorial_metrics["recall@10"],
        })
    rows.sort(key=lambda row: query_sort_key(row["query_id"]))
    return rows


def write_comparison_csv(rows, path):
    fieldnames = [
        "query_id", "bm25_map", "vectorial_map", "delta_map",
        "bm25_precision@10", "vectorial_precision@10", "delta_precision@10",
        "bm25_recall@10", "vectorial_recall@10", "delta_recall@10",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def comparison_lines(bm25, vectorial, rows, queries, top_diffs):
    bm25_aggregate = mean_metrics(bm25)
    vectorial_aggregate = mean_metrics(vectorial)
    lines = [
        f"Pipeline: {bm25['pipeline']}",
        f"BM25: {bm25['identifier']} (MAP={bm25_aggregate['map']:.4f}, P@10={bm25_aggregate['precision@10']:.4f}, R@10={bm25_aggregate['recall@10']:.4f})",
        f"Vectorial: {vectorial['identifier']} (MAP={vectorial_aggregate['map']:.4f}, P@10={vectorial_aggregate['precision@10']:.4f}, R@10={vectorial_aggregate['recall@10']:.4f})",
        "",
        f"Largest MAP differences (top {top_diffs} of {len(rows)} queries):",
    ]
    for row in sorted(rows, key=lambda row: abs(row["delta_map"]), reverse=True)[:top_diffs]:
        query_id = row["query_id"]
        lines.append("")
        lines.append(f"Query {query_id}: {queries.get(query_id, '')}")
        lines.append(
            f"  MAP bm25={row['bm25_map']:.4f} vectorial={row['vectorial_map']:.4f} delta={row['delta_map']:+.4f}"
        )
        lines.append(f"  BM25 top10: {format_ranking(bm25['ranking'].get(query_id), with_scores=True)}")
        lines.append(f"  VEC  top10: {format_ranking(vectorial['ranking'].get(query_id), with_scores=True)}")
    lines.append("")
    lines.append(
        f"Queries won by BM25: {sum(1 for row in rows if row['delta_map'] > 0)} | "
        f"won by Vectorial: {sum(1 for row in rows if row['delta_map'] < 0)} | "
        f"tied: {sum(1 for row in rows if row['delta_map'] == 0)}"
    )
    return lines


def per_query_lines(bm25, vectorial, rows, queries):
    groups = [
        ("Queries where BM25 is clearly superior", sorted(rows, key=lambda row: row["delta_map"], reverse=True)[:2]),
        ("Queries where Vectorial is clearly superior", sorted(rows, key=lambda row: row["delta_map"])[:2]),
        ("Queries where both perform poorly", sorted(rows, key=lambda row: max(row["bm25_map"], row["vectorial_map"]))[:2]),
    ]
    lines = []
    for title, group in groups:
        lines.append(f"=== {title} ===")
        for row in group:
            query_id = row["query_id"]
            lines.append("")
            lines.append(f"Query {query_id}: {queries.get(query_id, '')}")
            lines.append(f"  MAP bm25={row['bm25_map']:.4f} vectorial={row['vectorial_map']:.4f}")
            lines.append(f"  First 5 BM25: {format_ranking(bm25['ranking'].get(query_id), limit=5)}")
            lines.append(f"  First 5 VEC : {format_ranking(vectorial['ranking'].get(query_id), limit=5)}")
        lines.append("")
    return lines


def query_modification_lines(bm25, vectorial, queries):
    lines = []
    for original_query_id, modified_text in QUERY_MODIFICATIONS.items():
        modified_query_id = f"{original_query_id}{MODIFIED_QUERY_SUFFIX}"
        lines.append(f"Query {original_query_id} -> {modified_query_id}")
        lines.append(f"  original: {queries.get(original_query_id, '')}")
        lines.append(f"  modified: {modified_text}")
        for label, experiment in (("BM25", bm25), ("Vectorial", vectorial)):
            rankings = experiment["ranking"]
            if original_query_id not in rankings or modified_query_id not in rankings:
                lines.append(f"  {label}: no data for the modified query, re-run main.py")
                continue
            original_ranking = rankings[original_query_id]
            modified_ranking = rankings[modified_query_id]
            original_top = [doc_id for doc_id, _, _ in original_ranking]
            modified_top = [doc_id for doc_id, _, _ in modified_ranking]
            metrics = experiment["metrics"]
            original_map = metrics.get(original_query_id, {}).get("map", 0.0)
            modified_map = metrics.get(modified_query_id, {}).get("map", 0.0)
            entering = [doc_id for doc_id in modified_top if doc_id not in set(original_top)]
            leaving = [doc_id for doc_id in original_top if doc_id not in set(modified_top)]
            relevant_original = [doc_id for doc_id, _, relevance in original_ranking if relevance]
            relevant_modified = [doc_id for doc_id, _, relevance in modified_ranking if relevance]
            lines.append(
                f"  {label}: MAP {original_map:.4f} -> {modified_map:.4f}, top10 overlap {len(set(original_top) & set(modified_top))}/10"
            )
            lines.append(f"    entering top10: {' '.join(entering) if entering else '-'}")
            lines.append(f"    leaving  top10: {' '.join(leaving) if leaving else '-'}")
            lines.append(f"    relevant in original top10: {' '.join(relevant_original) if relevant_original else '-'}")
            lines.append(f"    relevant in modified top10: {' '.join(relevant_modified) if relevant_modified else '-'}")
            lines.append(f"    original top5: {format_ranking(original_ranking, limit=5)}")
            lines.append(f"    modified top5: {format_ranking(modified_ranking, limit=5)}")
        lines.append("")
    return lines


def build_posting_list(pipeline, docs):
    posting_list = PostingList(PipelineOptions[pipeline])
    posting_list.add_documents(docs)
    return posting_list


def document_evidence_lines(posting_list, query_text, pipeline, doc_id, docs, indent):
    query_terms = get_index_terms_freq(query_text, PipelineOptions[pipeline])
    total_documents = len(posting_list.document_lengths)
    total_length = sum(posting_list.document_lengths.values())
    average_length = total_length / total_documents if total_documents else 0.0
    document_length = posting_list.document_lengths.get(doc_id, 0)
    lines = [
        f"{indent}document {doc_id}: length={document_length}, avgdl={average_length:.2f}, text={docs.get(doc_id, '')[:220]!r}"
    ]
    matched = False
    for term in query_terms:
        term_frequency = posting_list.postings.get(term, {}).get(doc_id, 0)
        document_frequency = posting_list.document_frequencies.get(term, 0)
        if document_frequency:
            idf = log(1 + (total_documents - document_frequency + 0.5) / (document_frequency + 0.5))
        else:
            idf = 0.0
        lines.append(f"{indent}  term '{term}': tf={term_frequency}, df={document_frequency}, bm25_idf={idf:.2f}")
        matched = matched or term_frequency > 0
    if not matched:
        lines.append(f"{indent}  no query term occurs in the document after preprocessing")
    return lines


def error_analysis_lines(experiments, pipeline, queries, qrels_raw, docs, posting_list):
    lines = []
    for model in ("Probabilistic", "Vectorial"):
        experiment = best_experiment(experiments, model, pipeline)
        if experiment is None:
            continue
        lines.append(f"=== {model} ({experiment['identifier']}) ===")
        judged_false_positives = []
        unjudged_false_positives = []
        false_negatives = []
        for query_id in sorted(original_query_metrics(experiment), key=query_sort_key):
            ranking = experiment["ranking"].get(query_id, [])
            if not ranking:
                continue
            top_ids = {doc_id for doc_id, _, _ in ranking}
            judged = qrels_raw.get(query_id, {})
            for rank, (doc_id, score, relevance) in enumerate(ranking, start=1):
                if relevance:
                    continue
                raw_relevance = judged.get(doc_id)
                item = {
                    "query_id": query_id,
                    "doc_id": doc_id,
                    "rank": rank,
                    "score": score,
                    "judged": raw_relevance == -1,
                }
                if raw_relevance == -1:
                    judged_false_positives.append(item)
                elif raw_relevance is None:
                    unjudged_false_positives.append(item)
            relevant = {doc_id for doc_id, value in judged.items() if value > 0}
            missing = sorted(relevant - top_ids)
            if missing:
                false_negatives.append({"query_id": query_id, "missing": missing})

        false_positives = sorted(judged_false_positives, key=lambda item: (item["rank"], -item["score"]))
        false_positives += sorted(unjudged_false_positives, key=lambda item: (item["rank"], -item["score"]))
        for item in false_positives[:2]:
            query_text = queries.get(item["query_id"], "")
            judged_label = "judged relevance=-1" if item["judged"] else "unjudged"
            lines.append("")
            lines.append(
                f"Non-relevant doc at rank {item['rank']} for query {item['query_id']} (score={item['score']:.4f}, {judged_label})"
            )
            lines.append(f"  query: {query_text}")
            lines.extend(document_evidence_lines(posting_list, query_text, pipeline, item["doc_id"], docs, "  "))

        candidates = []
        options = PipelineOptions[pipeline]
        for item in false_negatives:
            query_text = queries.get(item["query_id"], "")
            query_terms = get_index_terms_freq(query_text, options)
            for doc_id in item["missing"]:
                term_frequency_sum = sum(
                    posting_list.postings.get(term, {}).get(doc_id, 0)
                    for term in query_terms
                )
                candidates.append((term_frequency_sum, item["query_id"], doc_id))
        candidates.sort(key=lambda candidate: candidate[0], reverse=True)
        selected = []
        seen_queries = set()
        for term_frequency_sum, query_id, doc_id in candidates:
            if query_id in seen_queries:
                continue
            seen_queries.add(query_id)
            selected.append((term_frequency_sum, query_id, doc_id))
            if len(selected) == 2:
                break
        for term_frequency_sum, query_id, doc_id in selected:
            query_text = queries.get(query_id, "")
            lines.append("")
            lines.append(
                f"Relevant doc {doc_id} missing from top-10 for query {query_id} (query-term tf sum={term_frequency_sum})"
            )
            lines.append(f"  query: {query_text}")
            lines.extend(document_evidence_lines(posting_list, query_text, pipeline, doc_id, docs, "  "))
        lines.append("")
    return lines


def parse_args():
    parser = argparse.ArgumentParser(
        description="Derives the model comparison, per-query, query-modification and error analyses from the experiment files in the result directory."
    )
    parser.add_argument("--result-dir", type=Path, default=REPO_ROOT / "result", help="Directory containing the experiment outputs")
    parser.add_argument("--pipeline", type=str, default=None, help="Preprocessing pipeline to analyse (default: pipeline of the best BM25 experiment)")
    parser.add_argument("--top-diffs", type=int, default=5, help="Number of queries shown in the model comparison")
    return parser.parse_args()


def main():
    args = parse_args()
    result_dir = args.result_dir
    if not result_dir.is_dir():
        sys.exit(f"result directory not found: {result_dir}")

    experiments = discover_experiments(result_dir)
    if not experiments:
        sys.exit(f"no experiment files found in {result_dir}")
    attach_rankings(experiments, result_dir)

    analysis_dir = result_dir / "analysis"
    analysis_dir.mkdir(parents=True, exist_ok=True)

    dataset = load("cranfield")
    queries = {query.query_id: query.text for query in dataset.queries_iter()}
    docs = {doc.doc_id: doc.text for doc in dataset.docs_iter()}
    qrels_raw = {}
    for qrel in dataset.qrels_iter():
        qrels_raw.setdefault(qrel.query_id, {})[qrel.doc_id] = qrel.relevance

    pipeline = args.pipeline or best_experiment(experiments, "Probabilistic")["pipeline"]
    if pipeline not in PipelineOptions.__members__:
        sys.exit(f"unknown pipeline: {pipeline}")

    bm25 = best_experiment(experiments, "Probabilistic", pipeline)
    vectorial = best_experiment(experiments, "Vectorial", pipeline)
    if bm25 is None or vectorial is None:
        sys.exit(f"pipeline {pipeline} needs both a Probabilistic and a Vectorial experiment")

    write_aggregated_csv(experiments, analysis_dir / "aggregated_metrics.csv")

    rows = build_comparison_rows(bm25, vectorial)
    write_comparison_csv(rows, analysis_dir / "model_comparison.csv")
    write_lines(analysis_dir / "model_comparison.txt", comparison_lines(bm25, vectorial, rows, queries, args.top_diffs))
    write_lines(analysis_dir / "per_query_analysis.txt", per_query_lines(bm25, vectorial, rows, queries))
    write_lines(analysis_dir / "query_modification.txt", query_modification_lines(bm25, vectorial, queries))

    posting_list = build_posting_list(pipeline, docs)
    write_lines(analysis_dir / "error_analysis.txt", error_analysis_lines(experiments, pipeline, queries, qrels_raw, docs, posting_list))

    print(f"Analysis written to {analysis_dir}")
    print(f"  pipeline: {pipeline}")
    print(f"  BM25: {bm25['identifier']} (MAP={mean_metrics(bm25)['map']:.4f})")
    print(f"  Vectorial: {vectorial['identifier']} (MAP={mean_metrics(vectorial)['map']:.4f})")
    print("  files: aggregated_metrics.csv, model_comparison.csv, model_comparison.txt, per_query_analysis.txt, query_modification.txt, error_analysis.txt")


if __name__ == "__main__":
    main()
