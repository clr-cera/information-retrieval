from __future__ import annotations

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
PROJECT_ROOT = Path(__file__).resolve().parent.parent
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
        partial_path = archive_path.with_name(archive_path.name + ".part")
        urllib.request.urlretrieve(url, partial_path)
        partial_path.replace(archive_path)

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

    return root


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
