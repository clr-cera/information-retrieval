from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
from itertools import product

from ir.lexical import PipelineOptions
from ir.data import RESULTS_DIR, load_experiment_config, save_experiment_config
from ir.lexical import LexicalIndex
from ir.lexical import evaluate_bm25
from ir.data import load_split

PIPELINE_OPTIONS = (
    PipelineOptions.NoStopRemovalNoStemming,
    PipelineOptions.WithStopRemovalNoStemming,
    PipelineOptions.NoStopRemovalWithStemming,
    PipelineOptions.WithStopRemovalWithStemming,
)
K1_VALUES = (0.5, 1.2, 2.0)
B_VALUES = (0.0, 0.75, 1.0)


@dataclass(frozen=True)
class TuningRow:
    split: str
    pipeline_options: str
    k1: float
    b: float
    P10: float
    R10: float
    AP10: float
    NDCG10: float
    document_count: int
    vocabulary_size: int
    posting_count: int
    build_time_seconds: float
    average_query_time_seconds: float


def main() -> None:
    parser = argparse.ArgumentParser(description="Tune BM25 on the dev split.")
    parser.add_argument("--split", default="dev")
    parser.add_argument("--update-config", action="store_true")
    args = parser.parse_args()

    split = load_split(args.split)
    documents = split.document_texts
    queries = split.query_texts
    qrels_by_query = split.qrels_by_query

    rows: list[TuningRow] = []
    for pipeline_options in PIPELINE_OPTIONS:
        print(f"Building index with {pipeline_options}")
        index = LexicalIndex(documents, pipeline_options)
        for k1, b in product(K1_VALUES, B_VALUES):
            run = evaluate_bm25(index, queries, qrels_by_query, k1, b)
            metrics = run.aggregated_metrics
            row = TuningRow(
                split=args.split,
                pipeline_options=str(pipeline_options),
                k1=k1,
                b=b,
                P10=metrics["P10"],
                R10=metrics["R10"],
                AP10=metrics["AP10"],
                NDCG10=metrics["NDCG10"],
                document_count=run.index_stats.document_count,
                vocabulary_size=run.index_stats.vocabulary_size,
                posting_count=run.index_stats.posting_count,
                build_time_seconds=run.index_stats.build_time_seconds,
                average_query_time_seconds=run.average_query_time_seconds,
            )
            rows.append(row)
            print(
                f"  k1={k1} b={b} "
                f"P10={row.P10:.4f} R10={row.R10:.4f} "
                f"AP10={row.AP10:.4f} NDCG10={row.NDCG10:.4f}"
            )

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    output_path = RESULTS_DIR / f"lexical_tuning_{args.split}.csv"
    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=list(asdict(rows[0])))
        writer.writeheader()
        writer.writerows(asdict(row) for row in rows)

    best = max(rows, key=lambda row: (row.NDCG10, row.AP10, row.P10))
    print(
        "Selected on "
        f"{args.split}: {best.pipeline_options}, k1={best.k1}, b={best.b}, "
        f"P10={best.P10:.4f}, R10={best.R10:.4f}, "
        f"AP10={best.AP10:.4f}, NDCG10={best.NDCG10:.4f}"
    )
    print(f"Tuning results written to {output_path}")

    if args.update_config:
        config = load_experiment_config()
        config["status"] = "lexical_tuned"
        config["selected"]["preprocessing"] = best.pipeline_options
        config["selected"]["lexical_model"] = "BM25"
        config["selected"]["bm25_k1"] = best.k1
        config["selected"]["bm25_b"] = best.b
        save_experiment_config(config)
        print("Updated config/tp2_experiment.json with the selected BM25 configuration")


if __name__ == "__main__":
    main()
