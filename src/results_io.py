from __future__ import annotations

import csv
import json
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path

from metrics import METRIC_KEYS

RANKING_COLUMNS = ("query_id", "doc_id", "rank", "score", "relevance")
METRICS_COLUMNS = ("query_id", "model", "P10", "R10", "AP10", "NDCG10")
TYPO_COLUMNS = (
    "query_id",
    "query_original",
    "query_erro",
    "query_corrigida",
    "tipo_erro",
    "NDCG10_original",
    "NDCG10_erro",
    "NDCG10_corrigida",
    "recuperacao",
    "erro_reduziu_desempenho",
)
RAG_COLUMNS = (
    "query_id",
    "query",
    "condition",
    "context_doc_ids",
    "prompt",
    "answer",
    "fidelidade",
    "completude",
    "utilidade",
    "rastreabilidade",
    "fidelidade_justificativa",
    "completude_justificativa",
    "utilidade_justificativa",
    "rastreabilidade_justificativa",
)

RAG_CONDITIONS = ("A", "B")


@dataclass(frozen=True)
class TypoExperimentRow:
    query_id: str
    query_original: str
    query_erro: str
    query_corrigida: str
    tipo_erro: str
    ndcg10_original: float
    ndcg10_erro: float
    ndcg10_corrigida: float
    recuperacao: float | None = None
    erro_reduziu_desempenho: bool | None = None

    def as_csv_dict(self) -> dict[str, object]:
        return {
            "query_id": self.query_id,
            "query_original": self.query_original,
            "query_erro": self.query_erro,
            "query_corrigida": self.query_corrigida,
            "tipo_erro": self.tipo_erro,
            "NDCG10_original": self.ndcg10_original,
            "NDCG10_erro": self.ndcg10_erro,
            "NDCG10_corrigida": self.ndcg10_corrigida,
            "recuperacao": _optional_value(self.recuperacao),
            "erro_reduziu_desempenho": _optional_value(self.erro_reduziu_desempenho),
        }


@dataclass(frozen=True)
class RagExperimentRow:
    query_id: str
    query: str
    condition: str
    context_doc_ids: Sequence[str]
    prompt: str
    answer: str
    fidelidade: int | None = None
    completude: int | None = None
    utilidade: int | None = None
    rastreabilidade: int | None = None
    fidelidade_justificativa: str = ""
    completude_justificativa: str = ""
    utilidade_justificativa: str = ""
    rastreabilidade_justificativa: str = ""

    def __post_init__(self) -> None:
        if self.condition not in RAG_CONDITIONS:
            raise ValueError(f"Invalid RAG condition {self.condition!r}. Expected one of {RAG_CONDITIONS}.")
        for name in ("fidelidade", "completude", "utilidade", "rastreabilidade"):
            value = getattr(self, name)
            if value is not None and value not in (0, 1, 2):
                raise ValueError(f"{name} must be 0, 1, 2 or None, got {value!r}.")

    def as_csv_dict(self) -> dict[str, object]:
        return {
            "query_id": self.query_id,
            "query": self.query,
            "condition": self.condition,
            "context_doc_ids": json.dumps(list(self.context_doc_ids), ensure_ascii=False),
            "prompt": self.prompt,
            "answer": self.answer,
            "fidelidade": _optional_value(self.fidelidade),
            "completude": _optional_value(self.completude),
            "utilidade": _optional_value(self.utilidade),
            "rastreabilidade": _optional_value(self.rastreabilidade),
            "fidelidade_justificativa": self.fidelidade_justificativa,
            "completude_justificativa": self.completude_justificativa,
            "utilidade_justificativa": self.utilidade_justificativa,
            "rastreabilidade_justificativa": self.rastreabilidade_justificativa,
        }


def write_ranking_csv(
    path: str | Path,
    rankings: Mapping[str, Sequence[tuple[str, float]]],
    qrels_by_query: Mapping[str, Mapping[str, int]],
    depth: int = 100,
) -> int:
    """Write query_id, doc_id, rank, score and relevance for at most ``depth`` documents per query."""
    output_path = _prepare_path(path)
    row_count = 0

    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=RANKING_COLUMNS)
        writer.writeheader()
        for query_id, ranked_docs in rankings.items():
            qrels = qrels_by_query.get(query_id, {})
            for rank, (doc_id, score) in enumerate(list(ranked_docs)[:depth], start=1):
                writer.writerow(
                    {
                        "query_id": query_id,
                        "doc_id": str(doc_id),
                        "rank": rank,
                        "score": float(score),
                        "relevance": qrels.get(str(doc_id), 0),
                    }
                )
                row_count += 1

    return row_count


def write_metrics_csv(
    path: str | Path,
    model: str,
    metrics_by_query: Mapping[str, Mapping[str, float]],
) -> int:
    """Write per-query P10, R10, AP10 and NDCG10 values for one model."""
    output_path = _prepare_path(path)
    row_count = 0

    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=METRICS_COLUMNS)
        writer.writeheader()
        for query_id, metrics in metrics_by_query.items():
            row = {"query_id": query_id, "model": model}
            row.update({metric: float(metrics[metric]) for metric in METRIC_KEYS})
            writer.writerow(row)
            row_count += 1

    return row_count


def write_combined_metrics_csv(
    path: str | Path,
    model_metrics: Mapping[str, Mapping[str, Mapping[str, float]]],
) -> int:
    """Write per-query metrics for multiple models into one CSV."""
    output_path = _prepare_path(path)
    row_count = 0

    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=METRICS_COLUMNS)
        writer.writeheader()
        for model, metrics_by_query in model_metrics.items():
            for query_id, metrics in metrics_by_query.items():
                row = {"query_id": query_id, "model": model}
                row.update({metric: float(metrics[metric]) for metric in METRIC_KEYS})
                writer.writerow(row)
                row_count += 1

    return row_count


def write_typo_experiment_csv(path: str | Path, rows: Iterable[TypoExperimentRow]) -> int:
    return _write_dataclass_rows(path, TYPO_COLUMNS, rows)


def write_rag_experiment_csv(path: str | Path, rows: Iterable[RagExperimentRow]) -> int:
    return _write_dataclass_rows(path, RAG_COLUMNS, rows)


def _write_dataclass_rows(
    path: str | Path,
    columns: Sequence[str],
    rows: Iterable[TypoExperimentRow | RagExperimentRow],
) -> int:
    output_path = _prepare_path(path)
    row_count = 0

    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row.as_csv_dict())
            row_count += 1

    return row_count


def _prepare_path(path: str | Path) -> Path:
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    return output_path


def _optional_value(value: object) -> object:
    return "N/A" if value is None else value
