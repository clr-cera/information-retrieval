"""Métricas de avaliação: P@k, R@k, AP@k, NDCG@k e Hit@k, por consulta e agregadas."""

from __future__ import annotations

# ============================================================================
# Origem: src/metrics.py
# ============================================================================

import math
from collections.abc import Mapping, Sequence

DEFAULT_CUTOFF = 10
METRIC_KEYS = ("P10", "R10", "AP10", "NDCG10")


def precision_at_k(ranked_doc_ids: Sequence[str], qrels: Mapping[str, int], k: int) -> float:
    if k <= 0:
        return 0.0
    relevant = _relevant_doc_ids(qrels)
    top_k = list(ranked_doc_ids)[:k]
    return sum(doc_id in relevant for doc_id in top_k) / k


def recall_at_k(ranked_doc_ids: Sequence[str], qrels: Mapping[str, int], k: int) -> float:
    relevant = _relevant_doc_ids(qrels)
    if not relevant:
        return 0.0
    top_k = list(ranked_doc_ids)[:k]
    return sum(doc_id in relevant for doc_id in top_k) / len(relevant)


def average_precision_at_k(ranked_doc_ids: Sequence[str], qrels: Mapping[str, int], k: int) -> float:
    relevant = _relevant_doc_ids(qrels)
    if not relevant:
        return 0.0

    hits = 0
    precision_sum = 0.0
    for rank, doc_id in enumerate(list(ranked_doc_ids)[:k], start=1):
        if doc_id in relevant:
            hits += 1
            precision_sum += hits / rank
    return precision_sum / len(relevant)


def ndcg_at_k(ranked_doc_ids: Sequence[str], qrels: Mapping[str, int], k: int) -> float:
    top_k = list(ranked_doc_ids)[:k]
    dcg = sum(
        max(qrels.get(doc_id, 0), 0) / math.log2(rank + 1)
        for rank, doc_id in enumerate(top_k, start=1)
    )

    ideal_grades = sorted((grade for grade in qrels.values() if grade > 0), reverse=True)[:k]
    idcg = sum(
        grade / math.log2(rank + 1)
        for rank, grade in enumerate(ideal_grades, start=1)
    )
    return dcg / idcg if idcg > 0 else 0.0


def hit_at_k(ranked_doc_ids: Sequence[str], qrels: Mapping[str, int], k: int) -> float:
    relevant = _relevant_doc_ids(qrels)
    return 1.0 if any(doc_id in relevant for doc_id in list(ranked_doc_ids)[:k]) else 0.0


def compute_metrics(ranked_doc_ids: Sequence[str], qrels: Mapping[str, int]) -> dict[str, float]:
    return {
        "P10": precision_at_k(ranked_doc_ids, qrels, DEFAULT_CUTOFF),
        "R10": recall_at_k(ranked_doc_ids, qrels, DEFAULT_CUTOFF),
        "AP10": average_precision_at_k(ranked_doc_ids, qrels, DEFAULT_CUTOFF),
        "NDCG10": ndcg_at_k(ranked_doc_ids, qrels, DEFAULT_CUTOFF),
    }


def compute_per_query_metrics(
    rankings: Mapping[str, Sequence[str]],
    qrels_by_query: Mapping[str, Mapping[str, int]],
) -> dict[str, dict[str, float]]:
    missing_rankings = sorted(set(qrels_by_query) - set(rankings))
    if missing_rankings:
        raise ValueError(
            f"Missing rankings for {len(missing_rankings)} judged queries: {missing_rankings[:5]}"
        )
    return {
        query_id: compute_metrics(rankings[query_id], qrels)
        for query_id, qrels in qrels_by_query.items()
    }


def aggregate_metrics(per_query_metrics: Mapping[str, Mapping[str, float]]) -> dict[str, float]:
    if not per_query_metrics:
        return {metric: 0.0 for metric in METRIC_KEYS}
    return {
        metric: sum(values[metric] for values in per_query_metrics.values()) / len(per_query_metrics)
        for metric in METRIC_KEYS
    }


def _relevant_doc_ids(qrels: Mapping[str, int]) -> set[str]:
    return {doc_id for doc_id, grade in qrels.items() if grade > 0}
