from __future__ import annotations

import argparse
import json
from pathlib import Path

from document_processor import PipelineOptions
from experiment_config import (
    LEXICAL_RESULTS_PATH,
    METRICS_PER_QUERY_PATH,
    RANKING_DEPTH,
    RESULTS_DIR,
    load_experiment_config,
)
from lexical_index import LexicalIndex
from lexical_retrieval import evaluate_bm25
from nfcorpus_loader import load_split
from results_io import write_metrics_csv, write_ranking_csv


def main() -> None:
    parser = argparse.ArgumentParser(description="Run BM25 lexical retrieval.")
    parser.add_argument("--split", default="test")
    parser.add_argument("--pipeline", choices=[option.name for option in PipelineOptions])
    parser.add_argument("--k1", type=float)
    parser.add_argument("--b", type=float)
    parser.add_argument("--rankings-output", type=Path)
    parser.add_argument("--metrics-output", type=Path)
    parser.add_argument("--stats-output", type=Path)
    args = parser.parse_args()

    config = load_experiment_config()
    selected = config["selected"]

    pipeline_name = args.pipeline or selected["preprocessing"]
    if pipeline_name is None:
        raise SystemExit("No preprocessing selected. Run tune_lexical.py --update-config first.")
    pipeline_options = PipelineOptions[pipeline_name]

    k1 = args.k1 if args.k1 is not None else selected["bm25_k1"]
    b = args.b if args.b is not None else selected["bm25_b"]
    if k1 is None or b is None:
        raise SystemExit("No BM25 parameters selected. Run tune_lexical.py --update-config first.")

    split = load_split(args.split)
    index = LexicalIndex(split.document_texts, pipeline_options)
    run = evaluate_bm25(index, split.query_texts, split.qrels_by_query, k1, b)

    if args.split == "test":
        default_rankings_path = LEXICAL_RESULTS_PATH
        default_metrics_path = METRICS_PER_QUERY_PATH
        default_stats_path = RESULTS_DIR / "lexical_stats.json"
    else:
        default_rankings_path = RESULTS_DIR / "dev" / "results_lexical.csv"
        default_metrics_path = RESULTS_DIR / "dev" / "metrics_per_query.csv"
        default_stats_path = RESULTS_DIR / "dev" / "lexical_stats.json"

    rankings_path = args.rankings_output or default_rankings_path
    metrics_path = args.metrics_output or default_metrics_path
    stats_path = args.stats_output or default_stats_path

    ranking_rows = write_ranking_csv(
        rankings_path,
        run.rankings,
        split.qrels_by_query,
        depth=RANKING_DEPTH,
    )
    metric_rows = write_metrics_csv(metrics_path, "lexical", run.metrics_by_query)

    stats = {
        "split": args.split,
        "pipeline_options": str(pipeline_options),
        "bm25_k1": k1,
        "bm25_b": b,
        "query_count": len(run.query_times),
        "index": run.index_stats.as_dict(),
        "average_query_time_seconds": run.average_query_time_seconds,
        "aggregated_metrics": run.aggregated_metrics,
    }
    stats_path.parent.mkdir(parents=True, exist_ok=True)
    with stats_path.open("w", encoding="utf-8") as output_file:
        json.dump(stats, output_file, indent=2, ensure_ascii=False)
        output_file.write("\n")

    print(
        f"BM25 on {args.split}: {stats['aggregated_metrics']}\n"
        f"Index: {stats['index']}\n"
        f"Average query time: {run.average_query_time_seconds:.6f}s\n"
        f"Wrote {ranking_rows} ranking rows to {rankings_path}\n"
        f"Wrote {metric_rows} metric rows to {metrics_path}\n"
        f"Wrote index/query statistics to {stats_path}"
    )


if __name__ == "__main__":
    main()
