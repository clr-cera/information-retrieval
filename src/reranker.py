from __future__ import annotations

from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from time import perf_counter

from metrics import aggregate_metrics, compute_per_query_metrics

RerankPredictor = Callable[[list[tuple[str, str]]], Sequence[float]]


@dataclass(frozen=True)
class RerankerRun:
    rankings: dict[str, list[tuple[str, float]]]
    metrics_by_query: dict[str, dict[str, float]]
    query_times: dict[str, float]
    aggregated_metrics: dict[str, float]
    model_name: str
    max_length: int
    truncated_pair_count: int
    device: str

    @property
    def average_rerank_time_seconds(self) -> float:
        if not self.query_times:
            return 0.0
        return sum(self.query_times.values()) / len(self.query_times)


def build_rerank_pairs(
    query: str,
    ranking: Sequence[tuple[str, float]],
    document_texts: Mapping[str, str],
    depth: int,
) -> tuple[list[tuple[str, float]], list[tuple[str, float]], list[tuple[str, str]]]:
    top = list(ranking[:depth])
    tail = list(ranking[depth:])
    pairs = [(query, document_texts[document_id]) for document_id, _ in top]
    return top, tail, pairs


def rerank_from_scores(
    top: Sequence[tuple[str, float]],
    tail: Sequence[tuple[str, float]],
    scores: Sequence[float],
) -> list[tuple[str, float]]:
    if len(top) != len(scores):
        raise ValueError("The number of reranker scores must match the number of candidates")
    reranked = [
        (document_id, float(score))
        for (document_id, _), score in zip(top, scores)
    ]
    reranked.sort(key=lambda item: (-item[1], item[0]))
    return reranked + list(tail)


def rerank_candidates(
    query: str,
    ranking: Sequence[tuple[str, float]],
    document_texts: Mapping[str, str],
    predict: RerankPredictor,
    depth: int = 50,
) -> list[tuple[str, float]]:
    top, tail, pairs = build_rerank_pairs(query, ranking, document_texts, depth)
    scores = predict(pairs)
    return rerank_from_scores(top, tail, scores)


class CrossEncoderReranker:
    def __init__(
        self,
        model_name: str,
        device: str | None = None,
        batch_size: int = 64,
    ):
        from sentence_transformers import CrossEncoder
        import torch

        self.model_name = model_name
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.model = CrossEncoder(model_name, device=self.device)
        self.max_length = int(self.model.max_length)
        self.tokenizer = self.model.tokenizer
        self.batch_size = batch_size

    def _predict(self, pairs: list[tuple[str, str]]) -> list[float]:
        scores = self.model.predict(
            pairs,
            batch_size=self.batch_size,
            show_progress_bar=False,
        )
        return [float(score) for score in scores]

    def _count_truncated_pairs(self, pairs: list[tuple[str, str]]) -> int:
        if not pairs:
            return 0
        encoded = self.tokenizer(
            pairs,
            truncation=False,
            padding=False,
            return_length=True,
        )
        return sum(length > self.max_length for length in encoded["length"])

    def rerank_query(
        self,
        query: str,
        ranking: Sequence[tuple[str, float]],
        document_texts: Mapping[str, str],
        depth: int = 50,
    ) -> tuple[list[tuple[str, float]], float, int]:
        start = perf_counter()
        top, tail, pairs = build_rerank_pairs(query, ranking, document_texts, depth)
        scores = self._predict(pairs)
        truncated = self._count_truncated_pairs(pairs)
        return (
            rerank_from_scores(top, tail, scores),
            perf_counter() - start,
            truncated,
        )


def evaluate_reranker(
    reranker: CrossEncoderReranker,
    hybrid_rankings: Mapping[str, Sequence[tuple[str, float]]],
    queries: Mapping[str, str],
    document_texts: Mapping[str, str],
    qrels_by_query: Mapping[str, Mapping[str, int]],
    depth: int = 50,
) -> RerankerRun:
    rankings: dict[str, list[tuple[str, float]]] = {}
    query_times: dict[str, float] = {}
    truncated_pair_count = 0

    for query_id, query_text in queries.items():
        rankings[query_id], query_times[query_id], truncated = reranker.rerank_query(
            query_text,
            hybrid_rankings[query_id],
            document_texts,
            depth=depth,
        )
        truncated_pair_count += truncated

    ranked_doc_ids = {
        query_id: [str(document_id) for document_id, _ in ranking]
        for query_id, ranking in rankings.items()
    }
    metrics_by_query = compute_per_query_metrics(ranked_doc_ids, qrels_by_query)

    return RerankerRun(
        rankings=rankings,
        metrics_by_query=metrics_by_query,
        query_times=query_times,
        aggregated_metrics=aggregate_metrics(metrics_by_query),
        model_name=reranker.model_name,
        max_length=reranker.max_length,
        truncated_pair_count=truncated_pair_count,
        device=reranker.device,
    )
