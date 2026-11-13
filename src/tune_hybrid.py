from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass

from experiment_config import (
    RRF_K_CANDIDATES,
    RESULTS_DIR,
    load_experiment_config,
    save_experiment_config,
)
from hybrid import evaluate_rankings, reciprocal_rank_fusion
from nfcorpus_loader import load_split
from retrieval_components import (
    build_lexical_run,
    build_semantic_run,
)


@dataclass(frozen=True)
class HybridTuningRow:
    rrf_k: int
    P10: float
    R10: float
    AP10: float
    NDCG10: float


def main() -> None:
    parser = argparse.ArgumentParser(description="Tune RRF k on dev.")
    parser.add_argument("--split", default="dev")
    parser.add_argument("--update-config", action="store_true")
    args = parser.parse_args()

    config = load_experiment_config()
    split = load_split(args.split)

    print("Running lexical retrieval")
    lexical_run = build_lexical_run(split, config)
    print(f"  Lexical NDCG10={lexical_run.aggregated_metrics['NDCG10']:.4f}")

    print("Running semantic retrieval")
    semantic_run = build_semantic_run(split, config)
    print(f"  Semantic NDCG10={semantic_run.aggregated_metrics['NDCG10']:.4f}")

    rows: list[HybridTuningRow] = []
    for rrf_k in RRF_K_CANDIDATES:
        fused_rankings = reciprocal_rank_fusion(
            lexical_run.rankings,
            semantic_run.rankings,
            rrf_k,
        )
        _, metrics = evaluate_rankings(fused_rankings, split.qrels_by_query)
        row = HybridTuningRow(
            rrf_k=rrf_k,
            P10=metrics["P10"],
            R10=metrics["R10"],
            AP10=metrics["AP10"],
            NDCG10=metrics["NDCG10"],
        )
        rows.append(row)
        print(
            f"  k={rrf_k} P10={row.P10:.4f} R10={row.R10:.4f} "
            f"AP10={row.AP10:.4f} NDCG10={row.NDCG10:.4f}"
        )

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    output_path = RESULTS_DIR / f"hybrid_tuning_{args.split}.csv"
    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=list(asdict(rows[0])))
        writer.writeheader()
        writer.writerows(asdict(row) for row in rows)

    best = max(rows, key=lambda row: (row.NDCG10, row.AP10, row.P10))
    print(
        f"Selected on {args.split}: RRF k={best.rrf_k}, "
        f"NDCG10={best.NDCG10:.4f}, AP10={best.AP10:.4f}"
    )
    print(f"Tuning results written to {output_path}")

    if args.update_config:
        config["selected"]["rrf_k"] = best.rrf_k
        config["status"] = "hybrid_tuned"
        save_experiment_config(config)
        print("Updated config/tp2_experiment.json with the selected RRF k")


if __name__ == "__main__":
    main()
