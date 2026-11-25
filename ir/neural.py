"""Sistemas neurais e híbrido: busca semântica (bi-encoder), RRF, reranking (cross-encoder) e montagem do pipeline."""

from __future__ import annotations

# ============================================================================
# Origem: src/semantic_retrieval.py
# ============================================================================

import json
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from time import perf_counter

import numpy as np

from ir.data import EMBEDDINGS_DIR
from ir.metrics import aggregate_metrics, compute_per_query_metrics


@dataclass(frozen=True)
class SemanticIndexStats:
    model_name: str
    embedding_dimension: int
    max_sequence_length: int
    document_count: int
    truncated_document_count: int
    embedding_time_seconds: float
    cache_hit: bool
    device: str

    def as_dict(self) -> dict[str, object]:
        return {
            "model_name": self.model_name,
            "embedding_dimension": self.embedding_dimension,
            "max_sequence_length": self.max_sequence_length,
            "document_count": self.document_count,
            "truncated_document_count": self.truncated_document_count,
            "embedding_time_seconds": self.embedding_time_seconds,
            "cache_hit": self.cache_hit,
            "device": self.device,
        }


@dataclass(frozen=True)
class SemanticRun:
    rankings: dict[str, list[tuple[str, float]]]
    metrics_by_query: dict[str, dict[str, float]]
    query_times: dict[str, float]
    aggregated_metrics: dict[str, float]
    index_stats: SemanticIndexStats

    @property
    def average_query_time_seconds(self) -> float:
        if not self.query_times:
            return 0.0
        return sum(self.query_times.values()) / len(self.query_times)


def rank_documents_by_dot_product(
    query_embedding: np.ndarray,
    document_embeddings: np.ndarray,
    document_ids: list[str],
    top_k: int | None = None,
) -> list[tuple[str, float]]:
    scores = document_embeddings @ query_embedding
    ranked = sorted(
        (
            (document_id, float(score))
            for document_id, score in zip(document_ids, scores)
        ),
        key=lambda item: (-item[1], item[0]),
    )
    return ranked[:top_k] if top_k is not None else ranked


class SemanticIndex:
    def __init__(
        self,
        documents: Mapping[str, str],
        model_name: str,
        device: str | None = None,
        batch_size: int = 32,
        cache_dir: str | Path = EMBEDDINGS_DIR,
    ):
        from sentence_transformers import SentenceTransformer
        import torch

        self.documents = dict(documents)
        self.model_name = model_name
        self.document_ids = list(self.documents)
        self.texts = [self.documents[document_id] for document_id in self.document_ids]
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.model = SentenceTransformer(model_name, device=self.device)
        if hasattr(self.model, "get_embedding_dimension"):
            self.embedding_dimension = int(self.model.get_embedding_dimension())
        else:
            self.embedding_dimension = int(self.model.get_sentence_embedding_dimension())
        self.max_sequence_length = int(self.model.max_seq_length)
        self.batch_size = batch_size
        self.cache_dir = Path(cache_dir)
        self._load_or_build_embeddings()

    def _cache_root(self) -> Path:
        safe_model_name = self.model_name.replace("/", "__").replace(":", "__")
        return self.cache_dir / safe_model_name

    def _load_or_build_embeddings(self) -> None:
        cache_root = self._cache_root()
        embeddings_path = cache_root / "document_embeddings.npy"
        document_ids_path = cache_root / "document_ids.json"
        metadata_path = cache_root / "metadata.json"

        if (
            embeddings_path.is_file()
            and document_ids_path.is_file()
            and metadata_path.is_file()
        ):
            cached_document_ids = json.loads(
                document_ids_path.read_text(encoding="utf-8")
            )
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            if (
                cached_document_ids == self.document_ids
                and metadata.get("model_name") == self.model_name
                and metadata.get("embedding_dimension") == self.embedding_dimension
                and metadata.get("normalized") is True
            ):
                self.embeddings = np.load(embeddings_path)
                self.truncated_document_count = int(
                    metadata.get("truncated_document_count", 0)
                )
                self.embedding_time_seconds = float(
                    metadata.get("embedding_time_seconds", 0.0)
                )
                self.cache_hit = True
                return

        start = perf_counter()
        self.truncated_document_count = self._count_truncated_documents()
        self.embeddings = self.model.encode(
            self.texts,
            batch_size=self.batch_size,
            normalize_embeddings=True,
            convert_to_numpy=True,
            show_progress_bar=False,
        )
        self.embedding_time_seconds = perf_counter() - start
        self.cache_hit = False

        cache_root.mkdir(parents=True, exist_ok=True)
        np.save(embeddings_path, self.embeddings)
        document_ids_path.write_text(
            json.dumps(self.document_ids, ensure_ascii=False),
            encoding="utf-8",
        )
        metadata = {
            "model_name": self.model_name,
            "embedding_dimension": self.embedding_dimension,
            "max_sequence_length": self.max_sequence_length,
            "document_count": len(self.document_ids),
            "truncated_document_count": self.truncated_document_count,
            "embedding_time_seconds": self.embedding_time_seconds,
            "normalized": True,
            "device": self.device,
        }
        metadata_path.write_text(
            json.dumps(metadata, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def _count_truncated_documents(self) -> int:
        tokenizer = self.model.tokenizer
        truncated = 0
        batch_size = 256
        for start in range(0, len(self.texts), batch_size):
            batch = self.texts[start : start + batch_size]
            encoded = tokenizer(
                batch,
                truncation=False,
                padding=False,
                return_length=True,
            )
            truncated += sum(
                length > self.max_sequence_length for length in encoded["length"]
            )
        return truncated

    @property
    def stats(self) -> SemanticIndexStats:
        return SemanticIndexStats(
            model_name=self.model_name,
            embedding_dimension=self.embedding_dimension,
            max_sequence_length=self.max_sequence_length,
            document_count=len(self.document_ids),
            truncated_document_count=self.truncated_document_count,
            embedding_time_seconds=self.embedding_time_seconds,
            cache_hit=self.cache_hit,
            device=self.device,
        )

    def search(
        self,
        query: str,
        top_k: int | None = 100,
    ) -> tuple[list[tuple[str, float]], float]:
        start = perf_counter()
        query_embedding = self.model.encode(
            [query],
            batch_size=1,
            normalize_embeddings=True,
            convert_to_numpy=True,
            show_progress_bar=False,
        )[0]
        ranking = rank_documents_by_dot_product(
            query_embedding,
            self.embeddings,
            self.document_ids,
            top_k=top_k,
        )
        return ranking, perf_counter() - start


def evaluate_semantic(
    index: SemanticIndex,
    queries: Mapping[str, str],
    qrels_by_query: Mapping[str, Mapping[str, int]],
    top_k: int = 100,
) -> SemanticRun:
    rankings: dict[str, list[tuple[str, float]]] = {}
    query_times: dict[str, float] = {}

    for query_id, query_text in queries.items():
        rankings[query_id], query_times[query_id] = index.search(
            query_text,
            top_k=top_k,
        )

    ranked_doc_ids = {
        query_id: [str(document_id) for document_id, _ in ranking]
        for query_id, ranking in rankings.items()
    }
    metrics_by_query = compute_per_query_metrics(ranked_doc_ids, qrels_by_query)

    return SemanticRun(
        rankings=rankings,
        metrics_by_query=metrics_by_query,
        query_times=query_times,
        aggregated_metrics=aggregate_metrics(metrics_by_query),
        index_stats=index.stats,
    )


# ============================================================================
# Origem: src/hybrid.py
# ============================================================================

from collections.abc import Mapping, Sequence

from ir.metrics import aggregate_metrics, compute_per_query_metrics


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


# ============================================================================
# Origem: src/reranker.py
# ============================================================================

from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from time import perf_counter

from ir.metrics import aggregate_metrics, compute_per_query_metrics

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


# ============================================================================
# Origem: src/retrieval_components.py
# ============================================================================

from ir.lexical import PipelineOptions
from ir.data import FUSION_DEPTH
from ir.lexical import LexicalIndex
from ir.lexical import LexicalRun, evaluate_bm25
from ir.data import NFCorpusSplit


def selected_lexical_config(config: dict) -> tuple[PipelineOptions, float, float]:
    selected = config["selected"]
    pipeline_name = selected.get("preprocessing")
    k1 = selected.get("bm25_k1")
    b = selected.get("bm25_b")
    if pipeline_name is None or k1 is None or b is None:
        raise ValueError("No lexical configuration selected. Run tune_lexical.py --update-config first.")
    return PipelineOptions[pipeline_name], float(k1), float(b)


def selected_semantic_model(config: dict) -> str:
    model_name = config["selected"].get("embedding_model")
    if model_name is None:
        raise ValueError("No embedding model selected. Run tune_semantic.py --update-config first.")
    return model_name


def selected_rrf_k(config: dict) -> int:
    rrf_k = config["selected"].get("rrf_k")
    if rrf_k is None:
        raise ValueError("No RRF k selected. Run tune_hybrid.py --update-config first.")
    return int(rrf_k)


def selected_reranker_model(config: dict) -> str:
    model_name = config["selected"].get("reranker_model")
    if model_name is None:
        raise ValueError("No reranker selected. Run tune_reranker.py --update-config first.")
    return model_name


def build_lexical_run(split: NFCorpusSplit, config: dict) -> LexicalRun:
    pipeline_options, k1, b = selected_lexical_config(config)
    index = LexicalIndex(split.document_texts, pipeline_options)
    return evaluate_bm25(index, split.query_texts, split.qrels_by_query, k1, b)


def build_semantic_run(split: NFCorpusSplit, config: dict) -> SemanticRun:
    index = SemanticIndex(split.document_texts, selected_semantic_model(config))
    return evaluate_semantic(
        index,
        split.query_texts,
        split.qrels_by_query,
        top_k=FUSION_DEPTH,
    )


def build_hybrid_rankings(
    lexical_run: LexicalRun,
    semantic_run: SemanticRun,
    rrf_k: int,
) -> dict[str, list[tuple[str, float]]]:
    return reciprocal_rank_fusion(
        lexical_run.rankings,
        semantic_run.rankings,
        rrf_k,
        depth=FUSION_DEPTH,
    )
