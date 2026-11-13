import json
import random
from pathlib import Path

import pytest

from nfcorpus_loader import (
    NFCORPUS_SPLITS,
    ensure_nfcorpus,
    load_all_splits,
    load_qrels,
    load_split,
    select_rag_query_ids,
)
from experiment_config import RAG_QUERY_IDS

OFFICIAL_DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "nfcorpus"


def _write_jsonl(path: Path, rows: list[dict]) -> None:
    path.write_text(
        "\n".join(json.dumps(row) for row in rows) + "\n",
        encoding="utf-8",
    )


def _write_synthetic_dataset(root: Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    (root / "qrels").mkdir(exist_ok=True)

    _write_jsonl(
        root / "corpus.jsonl",
        [
            {"_id": "MED-1", "title": "Title One", "text": "Body one"},
            {"_id": "MED-2", "title": "", "text": "Body two"},
            {"_id": "MED-3", "title": "Title Three", "text": "Body three"},
        ],
    )
    _write_jsonl(
        root / "queries.jsonl",
        [
            {"_id": f"PLAIN-{number}", "text": f"Question number {number}?"}
            for number in range(1, 13)
        ]
        + [{"_id": "PLAIN-13", "text": "This is a statement."}],
    )

    dev_rows = [
        "query-id\tcorpus-id\tscore",
        "PLAIN-1\tMED-1\t2",
        "PLAIN-2\tMED-2\t1",
        "PLAIN-2\tMED-3\t0",
    ]
    (root / "qrels" / "dev.tsv").write_text("\n".join(dev_rows) + "\n", encoding="utf-8")

    test_rows = ["query-id\tcorpus-id\tscore"]
    for number in range(1, 13):
        test_rows.append(f"PLAIN-{number}\tMED-{(number - 1) % 3 + 1}\t{number % 3}")
    test_rows.append("PLAIN-13\tMED-1\t1")
    (root / "qrels" / "test.tsv").write_text("\n".join(test_rows) + "\n", encoding="utf-8")

    (root / "qrels" / "train.tsv").write_text("query-id\tcorpus-id\tscore\n", encoding="utf-8")


def test_load_split_uses_title_plus_text_and_filters_unjudged_queries(tmp_path):
    _write_synthetic_dataset(tmp_path)
    split = load_split("dev", data_dir=tmp_path, download=False)

    assert split.name == "dev"
    assert set(split.documents) == {"MED-1", "MED-2", "MED-3"}
    assert split.document_texts["MED-1"] == "Title One Body one"
    assert split.document_texts["MED-2"] == "Body two"
    assert set(split.queries) == {"PLAIN-1", "PLAIN-2"}
    assert split.queries["PLAIN-1"].text == "Question number 1?"
    assert split.qrels_by_query == {
        "PLAIN-1": {"MED-1": 2},
        "PLAIN-2": {"MED-2": 1, "MED-3": 0},
    }


def test_load_all_splits_keeps_all_judged_test_queries(tmp_path):
    _write_synthetic_dataset(tmp_path)
    splits = load_all_splits(data_dir=tmp_path, download=False)

    assert tuple(splits) == NFCORPUS_SPLITS
    assert len(splits["test"].queries) == 13
    assert "PLAIN-13" in splits["test"].queries
    assert set(splits["test"].documents) == {"MED-1", "MED-2", "MED-3"}


def test_load_qrels_accepts_headerless_files(tmp_path):
    path = tmp_path / "qrels.tsv"
    path.write_text("PLAIN-1\tMED-1\t2\nPLAIN-1\tMED-2\t0\n", encoding="utf-8")

    qrels = load_qrels(path)
    assert [(qrel.query_id, qrel.doc_id, qrel.relevance) for qrel in qrels] == [
        ("PLAIN-1", "MED-1", 2),
        ("PLAIN-1", "MED-2", 0),
    ]


def test_load_qrels_skips_header_after_blank_line(tmp_path):
    path = tmp_path / "qrels.tsv"
    path.write_text("\nquery-id\tcorpus-id\tscore\nPLAIN-1\tMED-1\t2\n", encoding="utf-8")

    qrels = load_qrels(path)
    assert [(qrel.query_id, qrel.doc_id, qrel.relevance) for qrel in qrels] == [
        ("PLAIN-1", "MED-1", 2),
    ]


def test_select_rag_query_ids_is_deterministic(tmp_path):
    _write_synthetic_dataset(tmp_path)
    split = load_split("test", data_dir=tmp_path, download=False)

    question_ids = sorted(
        query_id
        for query_id, query in split.queries.items()
        if query.text.strip().endswith("?")
    )
    expected = random.Random(42).sample(question_ids, 10)

    assert select_rag_query_ids(split) == expected
    assert select_rag_query_ids(split) == expected
    assert len(expected) == 10


def test_missing_dataset_raises_without_download(tmp_path):
    with pytest.raises(FileNotFoundError, match="NFCorpus files not found"):
        load_split("test", data_dir=tmp_path / "missing", download=False)


def test_ensure_returns_existing_directory(tmp_path):
    _write_synthetic_dataset(tmp_path)
    assert ensure_nfcorpus(data_dir=tmp_path, download=False) == tmp_path.resolve()


@pytest.mark.skipif(
    not (OFFICIAL_DATA_DIR / "corpus.jsonl").is_file(),
    reason="Official NFCorpus files are not downloaded locally",
)
def test_official_nfcorpus_rag_queries_match_specification():
    split = load_split("test", download=False)

    assert len(split.documents) == 3633
    assert len(split.queries) == 323
    assert select_rag_query_ids(split) == list(RAG_QUERY_IDS)
