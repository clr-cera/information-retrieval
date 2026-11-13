from __future__ import annotations

import json
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from time import perf_counter

import numpy as np

from experiment_config import EMBEDDINGS_DIR
from metrics import aggregate_metrics, compute_per_query_metrics


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
