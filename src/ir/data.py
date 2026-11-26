"""Dados e configuração: leitura do NFCorpus (BEIR), configuração experimental e escrita dos CSVs de resultados."""

from __future__ import annotations

# ============================================================================
# Origem: src/nfcorpus_loader.py
# ============================================================================

import json
import os
import random
import shutil
import tempfile
import urllib.request
import zipfile
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

NFCORPUS_URL = "https://public.ukp.informatik.tu-darmstadt.de/thakur/BEIR/datasets/nfcorpus.zip"
NFCORPUS_SPLITS = ("train", "dev", "test")
DOWNLOAD_TIMEOUT_SECONDS = 30
# Fallback when the UKP server is unreachable: the same BEIR files mirrored on Hugging Face.
HF_CORPUS_REPO = "BeIR/nfcorpus"
HF_CORPUS_REVISION = "b5026a0e96e8a7ac4f95f482a596389289d46269"
HF_QRELS_REPO = "BeIR/nfcorpus-qrels"
HF_QRELS_REVISION = "a451b3b26d3ae1358f259c1a3a4dd61fcea35a65"
HF_FILES = {
    "corpus": f"https://huggingface.co/datasets/{HF_CORPUS_REPO}/resolve/{HF_CORPUS_REVISION}/corpus/corpus-00000-of-00001.parquet",
    "queries": f"https://huggingface.co/datasets/{HF_CORPUS_REPO}/resolve/{HF_CORPUS_REVISION}/queries/queries-00000-of-00001.parquet",
}
HF_QRELS_URL = f"https://huggingface.co/datasets/{HF_QRELS_REPO}/resolve/{HF_QRELS_REVISION}/{{split}}.tsv"
PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATA_DIR = PROJECT_ROOT / "data" / "nfcorpus"
RAG_QUERY_SEED = 42
RAG_QUERY_SAMPLE_SIZE = 10


@dataclass(frozen=True)
class Document:
    doc_id: str
    title: str
    text: str

    @property
    def searchable_text(self) -> str:
        parts = [part.strip() for part in (self.title, self.text) if part and part.strip()]
        return " ".join(parts)


@dataclass(frozen=True)
class Query:
    query_id: str
    text: str


@dataclass(frozen=True)
class Qrel:
    query_id: str
    doc_id: str
    relevance: int


@dataclass(frozen=True)
class NFCorpusSplit:
    name: str
    documents: dict[str, Document]
    queries: dict[str, Query]
    qrels: tuple[Qrel, ...]

    @property
    def qrels_by_query(self) -> dict[str, dict[str, int]]:
        grouped: dict[str, dict[str, int]] = {}
        for qrel in self.qrels:
            grouped.setdefault(qrel.query_id, {})[qrel.doc_id] = qrel.relevance
        return grouped

    @property
    def document_texts(self) -> dict[str, str]:
        return {
            doc_id: document.searchable_text
            for doc_id, document in self.documents.items()
        }

    @property
    def query_texts(self) -> dict[str, str]:
        return {
            query_id: query.text
            for query_id, query in self.queries.items()
        }


def default_data_dir() -> Path:
    return Path(os.environ.get("NFCORPUS_DIR", DEFAULT_DATA_DIR)).expanduser()


def ensure_nfcorpus(
    data_dir: str | Path | None = None,
    download: bool = True,
    url: str = NFCORPUS_URL,
) -> Path:
    """Return the NFCorpus directory, downloading and extracting the official BEIR archive if needed."""
    root = Path(data_dir) if data_dir is not None else default_data_dir()
    root = root.expanduser().resolve()

    if _has_required_files(root):
        return root

    if not download:
        raise FileNotFoundError(
            f"NFCorpus files not found in {root}. Re-run with download=True or set NFCORPUS_DIR."
        )

    archive_path = root.parent / "nfcorpus.zip"
    archive_path.parent.mkdir(parents=True, exist_ok=True)

    if not archive_path.exists():
        try:
            _download(url, archive_path)
        except OSError as error:
            print(
                f"Could not download the BEIR archive ({error}). "
                "Falling back to the Hugging Face copy (BeIR/nfcorpus + BeIR/nfcorpus-qrels)."
            )
            download_nfcorpus_from_huggingface(root)
            if not _has_required_files(root):
                raise RuntimeError(f"Hugging Face download did not produce the expected files in {root}")
            return root

    with tempfile.TemporaryDirectory(dir=archive_path.parent) as temporary_directory:
        temporary_path = Path(temporary_directory)
        with zipfile.ZipFile(archive_path) as archive:
            archive.extractall(temporary_path)

        extracted_root = temporary_path / "nfcorpus"
        if not extracted_root.is_dir():
            extracted_root = temporary_path

        root.mkdir(parents=True, exist_ok=True)
        shutil.copytree(extracted_root, root, dirs_exist_ok=True)

    if not _has_required_files(root):
        raise RuntimeError(f"Downloaded NFCorpus archive does not contain the expected files in {root}")

    _write_source_file(root, url)
    return root


def download_nfcorpus_from_huggingface(root: str | Path) -> Path:
    """Download NFCorpus from the BEIR copy on Hugging Face and write it in the BEIR file layout.

    Corpus and queries come as parquet (BeIR/nfcorpus); qrels come as TSV (BeIR/nfcorpus-qrels).
    Both repositories are pinned to fixed revisions for reproducibility.
    """
    import pandas as pd

    root = Path(root).expanduser().resolve()
    (root / "qrels").mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(dir=root.parent) as temporary_directory:
        temporary_path = Path(temporary_directory)
        for name, columns in (("corpus", ("_id", "title", "text")), ("queries", ("_id", "text"))):
            parquet_path = temporary_path / f"{name}.parquet"
            _download(HF_FILES[name], parquet_path)
            frame = pd.read_parquet(parquet_path)
            missing = [column for column in columns if column not in frame.columns]
            if missing:
                raise RuntimeError(f"Hugging Face {name} file is missing columns {missing}")
            with (root / f"{name}.jsonl").open("w", encoding="utf-8") as output_file:
                for record in frame[list(columns)].to_dict(orient="records"):
                    record = {key: "" if value is None else str(value) for key, value in record.items()}
                    output_file.write(json.dumps(record, ensure_ascii=False) + "\n")

    for split in NFCORPUS_SPLITS:
        _download(HF_QRELS_URL.format(split=split), root / "qrels" / f"{split}.tsv")

    _write_source_file(root, f"{HF_CORPUS_REPO}@{HF_CORPUS_REVISION} + {HF_QRELS_REPO}@{HF_QRELS_REVISION}")
    return root


def _download(url: str, destination: Path, timeout: float = DOWNLOAD_TIMEOUT_SECONDS) -> None:
    """Download to a .part file first so an interrupted download never looks complete."""
    partial_path = destination.with_name(destination.name + ".part")
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response, partial_path.open("wb") as output_file:
            shutil.copyfileobj(response, output_file)
    except BaseException:
        partial_path.unlink(missing_ok=True)
        raise
    partial_path.replace(destination)


def _write_source_file(root: Path, source: str) -> None:
    (root / "SOURCE.txt").write_text(source + "\n", encoding="utf-8")


def load_split(
    split: str,
    data_dir: str | Path | None = None,
    download: bool = True,
) -> NFCorpusSplit:
    """Load one official BEIR split, keeping only queries that have judgments in that split."""
    if split not in NFCORPUS_SPLITS:
        raise ValueError(f"Invalid split {split!r}. Expected one of {NFCORPUS_SPLITS}.")

    root = ensure_nfcorpus(data_dir=data_dir, download=download)
    return _load_split_cached(root, split)


def load_all_splits(
    data_dir: str | Path | None = None,
    download: bool = True,
) -> dict[str, NFCorpusSplit]:
    """Load train, dev and test splits sharing the same document collection."""
    root = ensure_nfcorpus(data_dir=data_dir, download=download)
    return {split: _load_split_cached(root, split) for split in NFCORPUS_SPLITS}


def select_rag_query_ids(
    split: NFCorpusSplit,
    seed: int = RAG_QUERY_SEED,
    sample_size: int = RAG_QUERY_SAMPLE_SIZE,
) -> list[str]:
    """Reproduce the TP2 RAG query sample: seeded sample of test questions ending in '?'."""
    question_ids = [
        query_id
        for query_id in sorted(split.queries)
        if split.queries[query_id].text.strip().endswith("?")
    ]
    if len(question_ids) < sample_size:
        raise ValueError(
            f"Split {split.name!r} has only {len(question_ids)} question queries, "
            f"needed {sample_size}."
        )
    return random.Random(seed).sample(question_ids, sample_size)


def load_corpus(path: str | Path) -> dict[str, Document]:
    documents: dict[str, Document] = {}
    with Path(path).open(encoding="utf-8") as corpus_file:
        for line in corpus_file:
            if not line.strip():
                continue
            record = json.loads(line)
            document = Document(
                doc_id=str(record["_id"]),
                title=record.get("title") or "",
                text=record.get("text") or "",
            )
            documents[document.doc_id] = document
    return documents


def load_queries(path: str | Path) -> dict[str, Query]:
    queries: dict[str, Query] = {}
    with Path(path).open(encoding="utf-8") as queries_file:
        for line in queries_file:
            if not line.strip():
                continue
            record = json.loads(line)
            query = Query(query_id=str(record["_id"]), text=record["text"])
            queries[query.query_id] = query
    return queries


def load_qrels(path: str | Path) -> tuple[Qrel, ...]:
    qrels: list[Qrel] = []
    first_content_row = True
    with Path(path).open(encoding="utf-8") as qrels_file:
        for line_number, line in enumerate(qrels_file, start=1):
            if not line.strip():
                continue
            fields = [field.strip() for field in line.rstrip("\n").split("\t")]
            if first_content_row:
                first_content_row = False
                if _is_qrels_header(fields):
                    continue
            if len(fields) < 3:
                raise ValueError(f"Malformed qrels row at {path}:{line_number}: {line!r}")
            qrels.append(
                Qrel(
                    query_id=fields[0],
                    doc_id=fields[1],
                    relevance=int(float(fields[2])),
                )
            )
    return tuple(qrels)


@lru_cache(maxsize=8)
def _load_split_cached(root: Path, split: str) -> NFCorpusSplit:
    documents = _load_corpus_cached(root / "corpus.jsonl")
    all_queries = _load_queries_cached(root / "queries.jsonl")
    qrels = load_qrels(root / "qrels" / f"{split}.tsv")

    judged_query_ids = {qrel.query_id for qrel in qrels}
    missing_queries = sorted(judged_query_ids - all_queries.keys())
    if missing_queries:
        raise ValueError(
            f"Split {split!r} references {len(missing_queries)} queries missing from queries.jsonl: "
            f"{missing_queries[:5]}"
        )

    queries = {
        query_id: query
        for query_id, query in all_queries.items()
        if query_id in judged_query_ids
    }
    return NFCorpusSplit(
        name=split,
        documents=documents,
        queries=queries,
        qrels=qrels,
    )


@lru_cache(maxsize=8)
def _load_corpus_cached(path: Path) -> dict[str, Document]:
    return load_corpus(path)


@lru_cache(maxsize=8)
def _load_queries_cached(path: Path) -> dict[str, Query]:
    return load_queries(path)


def _is_qrels_header(fields: list[str]) -> bool:
    normalized = fields[0].lower().replace("_", "-").replace(" ", "-")
    return normalized in {"query-id", "queryid"}


def _has_required_files(root: Path) -> bool:
    required = [root / "corpus.jsonl", root / "queries.jsonl"]
    required.extend(root / "qrels" / f"{split}.tsv" for split in NFCORPUS_SPLITS)
    return all(path.is_file() for path in required)


# ============================================================================
# Origem: src/experiment_config.py
# ============================================================================

import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"
NFCORPUS_DIR = DEFAULT_DATA_DIR
RESULTS_DIR = PROJECT_ROOT / "results"
EMBEDDINGS_DIR = DATA_DIR / "embeddings"
CONFIG_PATH = PROJECT_ROOT / "config" / "tp2_experiment.json"

LEXICAL_RESULTS_PATH = RESULTS_DIR / "results_lexical.csv"
SEMANTIC_RESULTS_PATH = RESULTS_DIR / "results_semantic.csv"
HYBRID_RESULTS_PATH = RESULTS_DIR / "results_hybrid.csv"
RERANKING_RESULTS_PATH = RESULTS_DIR / "results_reranking.csv"
METRICS_PER_QUERY_PATH = RESULTS_DIR / "metrics_per_query.csv"
TYPO_EXPERIMENT_PATH = RESULTS_DIR / "typo_experiment.csv"
RAG_EXPERIMENT_PATH = RESULTS_DIR / "rag_experiment.csv"

TUNING_SPLIT = "dev"
FINAL_SPLIT = "test"
EVALUATION_CUTOFF = 10
RANKING_DEPTH = 100
FUSION_DEPTH = 100
RERANK_DEPTH = 50
RRF_K_CANDIDATES = (10, 60, 100)

RAG_QUERY_IDS = (
    "PLAIN-68",
    "PLAIN-2450",
    "PLAIN-153",
    "PLAIN-2850",
    "PLAIN-2750",
    "PLAIN-270",
    "PLAIN-2470",
    "PLAIN-2430",
    "PLAIN-238",
    "PLAIN-3342",
)


def default_experiment_config() -> dict:
    return {
        "status": "pending_dev_tuning",
        "protocol": {
            "dataset": "NFCorpus",
            "source": NFCORPUS_URL,
            "splits": list(NFCORPUS_SPLITS),
            "document_representation": "title + text",
            "tuning_split": TUNING_SPLIT,
            "final_split": FINAL_SPLIT,
            "evaluation_cutoff": EVALUATION_CUTOFF,
            "ranking_depth": RANKING_DEPTH,
            "fusion_depth": FUSION_DEPTH,
            "rerank_depth": RERANK_DEPTH,
            "rrf_k_candidates": list(RRF_K_CANDIDATES),
            "rag_query_seed": RAG_QUERY_SEED,
            "rag_query_sample_size": RAG_QUERY_SAMPLE_SIZE,
            "rag_query_ids": list(RAG_QUERY_IDS),
        },
        "selected": {
            "preprocessing": None,
            "lexical_model": None,
            "bm25_k1": None,
            "bm25_b": None,
            "typo_kgram_size": None,
            "typo_jaccard_threshold": None,
            "typo_edit_distance_threshold": None,
            "embedding_model": None,
            "rrf_k": None,
            "reranker_model": None,
            "llm": None,
            "llm_temperature": 0,
            "llm_max_tokens": None,
            "rag_language": None,
        },
    }


def load_experiment_config(path: str | Path = CONFIG_PATH) -> dict:
    config_path = Path(path)
    with config_path.open(encoding="utf-8") as config_file:
        return json.load(config_file)


def save_experiment_config(config: dict, path: str | Path = CONFIG_PATH) -> Path:
    config_path = Path(path)
    config_path.parent.mkdir(parents=True, exist_ok=True)
    with config_path.open("w", encoding="utf-8") as config_file:
        json.dump(config, config_file, indent=2, ensure_ascii=False)
        config_file.write("\n")
    return config_path


def ensure_experiment_config(path: str | Path = CONFIG_PATH) -> dict:
    config_path = Path(path)
    if not config_path.exists():
        save_experiment_config(default_experiment_config(), config_path)
    return load_experiment_config(config_path)


# ============================================================================
# Origem: src/results_io.py
# ============================================================================

import csv
import json
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path

from ir.metrics import METRIC_KEYS

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
