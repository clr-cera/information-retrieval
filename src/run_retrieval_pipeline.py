from __future__ import annotations

import argparse
import json
from pathlib import Path

from experiment_config import (
    HYBRID_RESULTS_PATH,
    LEXICAL_RESULTS_PATH,
    METRICS_PER_QUERY_PATH,
    RANKING_DEPTH,
    RERANK_DEPTH,
    RERANKING_RESULTS_PATH,
    RESULTS_DIR,
    SEMANTIC_RESULTS_PATH,
    load_experiment_config,
)
from hybrid import evaluate_rankings
from nfcorpus_loader import load_split
from reranker import CrossEncoderReranker, evaluate_reranker
from results_io import write_combined_metrics_csv, write_ranking_csv
from retrieval_components import (
    build_hybrid_rankings,
    build_lexical_run,
    build_semantic_run,
    selected_reranker_model,
    selected_rrf_k,
)


def output_paths(split: str) -> dict[str, Path]:
    if split == "test":
        return {
            "lexical": LEXICAL_RESULTS_PATH,
            "semantic": SEMANTIC_RESULTS_PATH,
            "hybrid": HYBRID_RESULTS_PATH,
            "reranking": RERANKING_RESULTS_PATH,
            "metrics": METRICS_PER_QUERY_PATH,
            "summary": RESULTS_DIR / "retrieval_summary.json",
            "lexical_stats": RESULTS_DIR / "lexical_stats.json",
            "semantic_stats": RESULTS_DIR / "semantic_stats.json",
            "reranking_stats": RESULTS_DIR / "reranking_stats.json",
        }

    dev_dir = RESULTS_DIR / split
    return {
        "lexical": dev_dir / "results_lexical.csv",
        "semantic": dev_dir / "results_semantic.csv",
        "hybrid": dev_dir / "results_hybrid.csv",
        "reranking": dev_dir / "results_reranking.csv",
        "metrics": dev_dir / "metrics_per_query.csv",
        "summary": dev_dir / "retrieval_summary.json",
        "lexical_stats": dev_dir / "lexical_stats.json",
        "semantic_stats": dev_dir / "semantic_stats.json",
        "reranking_stats": dev_dir / "reranking_stats.json",
    }


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as output_file:
        json.dump(data, output_file, indent=2, ensure_ascii=False)
        output_file.write("\n")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run lexical, semantic, hybrid and reranking retrieval."
    )
    parser.add_argument("--split", default="test")
    args = parser.parse_args()

    config = load_experiment_config()
    split = load_split(args.split)
    paths = output_paths(args.split)

    print("Running lexical retrieval")
    lexical_run = build_lexical_run(split, config)
    print("Running semantic retrieval")
    semantic_run = build_semantic_run(split, config)
    print("Running hybrid RRF")
    hybrid_rankings = build_hybrid_rankings(
        lexical_run,
        semantic_run,
        selected_rrf_k(config),
    )
    hybrid_metrics, hybrid_aggregated = evaluate_rankings(
        hybrid_rankings,
        split.qrels_by_query,
    )
    print("Running cross-encoder reranking")
    reranker = CrossEncoderReranker(selected_reranker_model(config))
    reranker_run = evaluate_reranker(
        reranker,
        hybrid_rankings,
        split.query_texts,
        split.document_texts,
        split.qrels_by_query,
        depth=RERANK_DEPTH,
    )

    ranking_rows = {
        "lexical": write_ranking_csv(
            paths["lexical"],
            lexical_run.rankings,
            split.qrels_by_query,
            depth=RANKING_DEPTH,
        ),
        "semantic": write_ranking_csv(
            paths["semantic"],
            semantic_run.rankings,
            split.qrels_by_query,
            depth=RANKING_DEPTH,
        ),
        "hybrid": write_ranking_csv(
            paths["hybrid"],
            hybrid_rankings,
            split.qrels_by_query,
            depth=RANKING_DEPTH,
        ),
        "reranking": write_ranking_csv(
            paths["reranking"],
            reranker_run.rankings,
            split.qrels_by_query,
            depth=RANKING_DEPTH,
        ),
    }

    metric_rows = write_combined_metrics_csv(
        paths["metrics"],
        {
            "lexical": lexical_run.metrics_by_query,
            "semantic": semantic_run.metrics_by_query,
            "hybrid": hybrid_metrics,
            "reranking": reranker_run.metrics_by_query,
        },
    )

    write_json(
        paths["lexical_stats"],
        {
            "split": args.split,
            "pipeline_options": config["selected"]["preprocessing"],
            "bm25_k1": config["selected"]["bm25_k1"],
            "bm25_b": config["selected"]["bm25_b"],
            "query_count": len(lexical_run.query_times),
            "index": lexical_run.index_stats.as_dict(),
            "average_query_time_seconds": lexical_run.average_query_time_seconds,
            "aggregated_metrics": lexical_run.aggregated_metrics,
        },
    )
    write_json(
        paths["semantic_stats"],
        {
            "split": args.split,
            "query_count": len(semantic_run.query_times),
            "index": semantic_run.index_stats.as_dict(),
            "average_query_time_seconds": semantic_run.average_query_time_seconds,
            "aggregated_metrics": semantic_run.aggregated_metrics,
        },
    )
    write_json(
        paths["reranking_stats"],
        {
            "split": args.split,
            "model_name": reranker_run.model_name,
            "max_length": reranker_run.max_length,
            "truncated_pair_count": reranker_run.truncated_pair_count,
            "device": reranker_run.device,
            "query_count": len(reranker_run.query_times),
            "average_rerank_time_seconds": reranker_run.average_rerank_time_seconds,
            "hybrid_aggregated_metrics": hybrid_aggregated,
            "aggregated_metrics": reranker_run.aggregated_metrics,
        },
    )

    summary = {
        "split": args.split,
        "selected": config["selected"],
        "aggregated_metrics": {
            "lexical": lexical_run.aggregated_metrics,
            "semantic": semantic_run.aggregated_metrics,
            "hybrid": hybrid_aggregated,
            "reranking": reranker_run.aggregated_metrics,
        },
        "ranking_rows": ranking_rows,
        "metric_rows": metric_rows,
    }
    write_json(paths["summary"], summary)

    print(f"\nResults on {args.split}")
    for system, metrics in summary["aggregated_metrics"].items():
        print(
            f"  {system:10s} P10={metrics['P10']:.4f} R10={metrics['R10']:.4f} "
            f"AP10={metrics['AP10']:.4f} NDCG10={metrics['NDCG10']:.4f}"
        )
    print(
        f"\nAverage query time: lexical={lexical_run.average_query_time_seconds:.4f}s "
        f"semantic={semantic_run.average_query_time_seconds:.4f}s "
        f"reranking={reranker_run.average_rerank_time_seconds:.4f}s"
    )
    print(f"Summary written to {paths['summary']}")


if __name__ == "__main__":
    main()
