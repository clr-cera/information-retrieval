from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass

from experiment_config import FUSION_DEPTH, RESULTS_DIR, load_experiment_config, save_experiment_config
from nfcorpus_loader import load_split
from semantic_retrieval import SemanticIndex, evaluate_semantic

SEMANTIC_MODELS = (
    "sentence-transformers/all-MiniLM-L6-v2",
    "sentence-transformers/multi-qa-MiniLM-L6-cos-v1",
)


@dataclass(frozen=True)
class SemanticTuningRow:
    model_name: str
    embedding_dimension: int
    max_sequence_length: int
    document_count: int
    truncated_document_count: int
    embedding_time_seconds: float
    cache_hit: bool
    device: str
    P10: float
    R10: float
    AP10: float
    NDCG10: float
    average_query_time_seconds: float


def main() -> None:
    parser = argparse.ArgumentParser(description="Tune the semantic bi-encoder on dev.")
    parser.add_argument("--split", default="dev")
    parser.add_argument("--update-config", action="store_true")
    args = parser.parse_args()

    split = load_split(args.split)
    rows: list[SemanticTuningRow] = []

    for model_name in SEMANTIC_MODELS:
        print(f"Loading {model_name}")
        try:
            index = SemanticIndex(split.document_texts, model_name)
            run = evaluate_semantic(
                index,
                split.query_texts,
                split.qrels_by_query,
                top_k=FUSION_DEPTH,
            )
        except Exception as error:
            print(f"  Skipping {model_name}: {error}")
            continue

        metrics = run.aggregated_metrics
        stats = run.index_stats
        row = SemanticTuningRow(
            model_name=model_name,
            embedding_dimension=stats.embedding_dimension,
            max_sequence_length=stats.max_sequence_length,
            document_count=stats.document_count,
            truncated_document_count=stats.truncated_document_count,
            embedding_time_seconds=stats.embedding_time_seconds,
            cache_hit=stats.cache_hit,
            device=stats.device,
            P10=metrics["P10"],
            R10=metrics["R10"],
            AP10=metrics["AP10"],
            NDCG10=metrics["NDCG10"],
            average_query_time_seconds=run.average_query_time_seconds,
        )
        rows.append(row)
        print(
            f"  P10={row.P10:.4f} R10={row.R10:.4f} "
            f"AP10={row.AP10:.4f} NDCG10={row.NDCG10:.4f} "
            f"embed_time={row.embedding_time_seconds:.2f}s "
            f"query_time={row.average_query_time_seconds:.4f}s"
        )

    if not rows:
        raise SystemExit("No semantic model could be evaluated.")

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    output_path = RESULTS_DIR / f"semantic_tuning_{args.split}.csv"
    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=list(asdict(rows[0])))
        writer.writeheader()
        writer.writerows(asdict(row) for row in rows)

    best = max(rows, key=lambda row: (row.NDCG10, row.AP10, row.P10))
    print(
        f"Selected on {args.split}: {best.model_name}, "
        f"NDCG10={best.NDCG10:.4f}, AP10={best.AP10:.4f}"
    )
    print(f"Tuning results written to {output_path}")

    if args.update_config:
        config = load_experiment_config()
        config["selected"]["embedding_model"] = best.model_name
        config["status"] = "semantic_tuned"
        save_experiment_config(config)
        print("Updated config/tp2_experiment.json with the selected embedding model")


if __name__ == "__main__":
    main()
