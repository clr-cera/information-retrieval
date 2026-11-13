from __future__ import annotations

from collections.abc import Mapping, Sequence

from metrics import aggregate_metrics, compute_per_query_metrics


def reciprocal_rank_fusion(
    lexical_rankings: Mapping[str, Sequence[tuple[str, float]]],
    semantic_rankings: Mapping[str, Sequence[tuple[str, float]]],
    k: int,
    depth: int = 100,
) -> dict[str, list[tuple[str, float]]]:
    if k <= 0:
        raise ValueError("RRF k must be positive")
    if set(lexical_rankings) != set(semantic_rankings):
        raise ValueError("Lexical and semantic rankings must cover the same queries")

    fused: dict[str, list[tuple[str, float]]] = {}
    for query_id in lexical_rankings:
        scores: dict[str, float] = {}
        for ranking in (lexical_rankings[query_id], semantic_rankings[query_id]):
            for rank, (document_id, _) in enumerate(ranking[:depth], start=1):
                scores[document_id] = scores.get(document_id, 0.0) + 1.0 / (k + rank)
        fused[query_id] = sorted(
            scores.items(),
            key=lambda item: (-item[1], item[0]),
        )
    return fused


def evaluate_rankings(
    rankings: Mapping[str, Sequence[tuple[str, float]]],
    qrels_by_query: Mapping[str, Mapping[str, int]],
) -> tuple[dict[str, dict[str, float]], dict[str, float]]:
    ranked_doc_ids = {
        query_id: [str(document_id) for document_id, _ in ranking]
        for query_id, ranking in rankings.items()
    }
    metrics_by_query = compute_per_query_metrics(ranked_doc_ids, qrels_by_query)
    return metrics_by_query, aggregate_metrics(metrics_by_query)
