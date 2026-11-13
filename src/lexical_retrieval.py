from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from time import perf_counter

from lexical_index import IndexStats, LexicalIndex
from metrics import aggregate_metrics, compute_per_query_metrics


@dataclass(frozen=True)
class LexicalRun:
    rankings: dict[str, list[tuple[str, float]]]
    metrics_by_query: dict[str, dict[str, float]]
    query_times: dict[str, float]
    aggregated_metrics: dict[str, float]
    index_stats: IndexStats

    @property
    def average_query_time_seconds(self) -> float:
        if not self.query_times:
            return 0.0
        return sum(self.query_times.values()) / len(self.query_times)


def evaluate_bm25(
    index: LexicalIndex,
    queries: Mapping[str, str],
    qrels_by_query: Mapping[str, Mapping[str, int]],
    k1: float,
    b: float,
) -> LexicalRun:
    model = index.build_bm25(k1, b)
    rankings: dict[str, list[tuple[str, float]]] = {}
    query_times: dict[str, float] = {}

    for query_id, query_text in queries.items():
        start = perf_counter()
        rankings[query_id] = model.execute_query(query_text, return_scores=True)
        query_times[query_id] = perf_counter() - start

    ranked_doc_ids = {
        query_id: [str(doc_id) for doc_id, _ in ranking]
        for query_id, ranking in rankings.items()
    }
    metrics_by_query = compute_per_query_metrics(ranked_doc_ids, qrels_by_query)

    return LexicalRun(
        rankings=rankings,
        metrics_by_query=metrics_by_query,
        query_times=query_times,
        aggregated_metrics=aggregate_metrics(metrics_by_query),
        index_stats=index.stats,
    )
