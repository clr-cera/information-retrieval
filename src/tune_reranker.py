from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass

from experiment_config import (
    RERANK_DEPTH,
    RESULTS_DIR,
    load_experiment_config,
    save_experiment_config,
)
from nfcorpus_loader import load_split
from reranker import CrossEncoderReranker, evaluate_reranker
from retrieval_components import (
    build_hybrid_rankings,
    build_lexical_run,
    build_semantic_run,
    selected_rrf_k,
)

RERANKER_MODELS = (
    "cross-encoder/ms-marco-MiniLM-L6-v2",
    "cross-encoder/ms-marco-TinyBERT-L2-v2",
)


@dataclass(frozen=True)
class RerankerTuningRow:
    model_name: str
    max_length: int
    truncated_pair_count: int
    device: str
    average_rerank_time_seconds: float
    P10: float
    R10: float
    AP10: float
    NDCG10: float


def main() -> None:
    parser = argparse.ArgumentParser(description="Tune the cross-encoder reranker on dev.")
    parser.add_argument("--split", default="dev")
    parser.add_argument("--update-config", action="store_true")
    args = parser.parse_args()

    config = load_experiment_config()
    split = load_split(args.split)

    print("Running lexical and semantic retrieval")
    lexical_run = build_lexical_run(split, config)
    semantic_run = build_semantic_run(split, config)
    hybrid_rankings = build_hybrid_rankings(
        lexical_run,
        semantic_run,
        selected_rrf_k(config),
    )
    print("Hybrid rankings ready")

    rows: list[RerankerTuningRow] = []
    for model_name in RERANKER_MODELS:
        print(f"Loading {model_name}")
        try:
            reranker = CrossEncoderReranker(model_name)
            run = evaluate_reranker(
                reranker,
                hybrid_rankings,
                split.query_texts,
                split.document_texts,
                split.qrels_by_query,
                depth=RERANK_DEPTH,
            )
        except Exception as error:
            print(f"  Skipping {model_name}: {error}")
            continue

        metrics = run.aggregated_metrics
        row = RerankerTuningRow(
            model_name=model_name,
            max_length=run.max_length,
            truncated_pair_count=run.truncated_pair_count,
            device=run.device,
            average_rerank_time_seconds=run.average_rerank_time_seconds,
            P10=metrics["P10"],
            R10=metrics["R10"],
            AP10=metrics["AP10"],
            NDCG10=metrics["NDCG10"],
        )
        rows.append(row)
        print(
            f"  P10={row.P10:.4f} R10={row.R10:.4f} "
            f"AP10={row.AP10:.4f} NDCG10={row.NDCG10:.4f} "
            f"rerank_time={row.average_rerank_time_seconds:.4f}s"
        )

    if not rows:
        raise SystemExit("No reranker model could be evaluated.")

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    output_path = RESULTS_DIR / f"reranker_tuning_{args.split}.csv"
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
        config["selected"]["reranker_model"] = best.model_name
        config["status"] = "retrieval_tuned"
        save_experiment_config(config)
        print("Updated config/tp2_experiment.json with the selected reranker model")


if __name__ == "__main__":
    main()
