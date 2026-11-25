"""Testes de ir.data."""

from __future__ import annotations

# ============================================================================
# Origem: src/nfcorpus_loader_test.py
# ============================================================================

import json
import random
from pathlib import Path

import pytest

from ir.data import NFCORPUS_SPLITS, ensure_nfcorpus, load_all_splits, load_qrels, load_split, select_rag_query_ids
from ir.data import RAG_QUERY_IDS

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


# ============================================================================
# Origem: src/experiment_config_test.py
# ============================================================================

from ir.data import RAG_QUERY_IDS, default_experiment_config, ensure_experiment_config, load_experiment_config, save_experiment_config


def test_default_config_encodes_frozen_protocol():
    config = default_experiment_config()
    protocol = config["protocol"]

    assert protocol["tuning_split"] == "dev"
    assert protocol["final_split"] == "test"
    assert protocol["document_representation"] == "title + text"
    assert protocol["evaluation_cutoff"] == 10
    assert protocol["ranking_depth"] == 100
    assert protocol["fusion_depth"] == 100
    assert protocol["rerank_depth"] == 50
    assert protocol["rrf_k_candidates"] == [10, 60, 100]
    assert protocol["rag_query_seed"] == 42
    assert protocol["rag_query_ids"] == list(RAG_QUERY_IDS)


def test_rag_query_ids_are_unique_and_complete():
    assert len(RAG_QUERY_IDS) == 10
    assert len(set(RAG_QUERY_IDS)) == 10


def test_config_round_trip(tmp_path):
    path = tmp_path / "nested" / "tp2_experiment.json"
    config = default_experiment_config()
    config["selected"]["lexical_model"] = "BM25"

    save_experiment_config(config, path)

    assert path.is_file()
    assert load_experiment_config(path) == config


def test_ensure_experiment_config_creates_default_file(tmp_path):
    path = tmp_path / "tp2_experiment.json"

    config = ensure_experiment_config(path)

    assert path.is_file()
    assert config == default_experiment_config()


# ============================================================================
# Origem: src/results_io_test.py
# ============================================================================

import csv
import json

import pytest

from ir.data import RANKING_COLUMNS, RagExperimentRow, TypoExperimentRow, write_combined_metrics_csv, write_metrics_csv, write_rag_experiment_csv, write_ranking_csv, write_typo_experiment_csv


def _read_csv(path):
    with path.open(newline="", encoding="utf-8") as input_file:
        reader = csv.DictReader(input_file)
        return reader.fieldnames, list(reader)


def test_write_ranking_csv_limits_depth_and_adds_relevance(tmp_path):
    rankings = {"q1": [(f"d{number}", float(200 - number)) for number in range(1, 106)]}
    qrels = {"q1": {"d1": 2, "d50": 1, "d101": 1}}
    output = tmp_path / "nested" / "results_lexical.csv"

    written = write_ranking_csv(output, rankings, qrels, depth=100)
    fieldnames, rows = _read_csv(output)

    assert written == 100
    assert fieldnames == list(RANKING_COLUMNS)
    assert len(rows) == 100
    assert rows[0] == {
        "query_id": "q1",
        "doc_id": "d1",
        "rank": "1",
        "score": "199.0",
        "relevance": "2",
    }
    assert rows[49]["doc_id"] == "d50"
    assert rows[49]["relevance"] == "1"
    assert rows[-1]["doc_id"] == "d100"
    assert rows[-1]["relevance"] == "0"
    assert all(row["doc_id"] != "d101" for row in rows)


def test_write_metrics_csv(tmp_path):
    output = tmp_path / "metrics_per_query.csv"
    metrics = {"q1": {"P10": 0.1, "R10": 0.2, "AP10": 0.3, "NDCG10": 0.4}}

    written = write_metrics_csv(output, "lexical", metrics)
    fieldnames, rows = _read_csv(output)

    assert written == 1
    assert fieldnames == ["query_id", "model", "P10", "R10", "AP10", "NDCG10"]
    assert rows == [
        {
            "query_id": "q1",
            "model": "lexical",
            "P10": "0.1",
            "R10": "0.2",
            "AP10": "0.3",
            "NDCG10": "0.4",
        }
    ]


def test_write_combined_metrics_csv(tmp_path):
    output = tmp_path / "metrics_per_query.csv"
    model_metrics = {
        "lexical": {"q1": {"P10": 0.1, "R10": 0.2, "AP10": 0.3, "NDCG10": 0.4}},
        "semantic": {"q1": {"P10": 0.5, "R10": 0.6, "AP10": 0.7, "NDCG10": 0.8}},
    }

    written = write_combined_metrics_csv(output, model_metrics)
    fieldnames, rows = _read_csv(output)

    assert written == 2
    assert fieldnames == ["query_id", "model", "P10", "R10", "AP10", "NDCG10"]
    assert [row["model"] for row in rows] == ["lexical", "semantic"]
    assert rows[1]["NDCG10"] == "0.8"


def test_write_typo_experiment_csv(tmp_path):
    output = tmp_path / "typo_experiment.csv"
    rows = [
        TypoExperimentRow(
            query_id="PLAIN-1",
            query_original="original query",
            query_erro="origional query",
            query_corrigida="original query",
            tipo_erro="substituicao",
            ndcg10_original=0.8,
            ndcg10_erro=0.2,
            ndcg10_corrigida=0.7,
            recuperacao=5 / 6,
            erro_reduziu_desempenho=True,
        ),
        TypoExperimentRow(
            query_id="PLAIN-2",
            query_original="another query",
            query_erro="anothr query",
            query_corrigida="another query",
            tipo_erro="remocao",
            ndcg10_original=0.0,
            ndcg10_erro=0.0,
            ndcg10_corrigida=0.0,
        ),
    ]

    written = write_typo_experiment_csv(output, rows)
    fieldnames, parsed = _read_csv(output)

    assert written == 2
    assert "tipo_erro" in fieldnames
    assert parsed[0]["recuperacao"] == str(5 / 6)
    assert parsed[0]["erro_reduziu_desempenho"] == "True"
    assert parsed[1]["recuperacao"] == "N/A"
    assert parsed[1]["erro_reduziu_desempenho"] == "N/A"


def test_write_rag_experiment_csv_serializes_context_and_scores(tmp_path):
    output = tmp_path / "rag_experiment.csv"
    rows = [
        RagExperimentRow(
            query_id="PLAIN-1",
            query="Is this useful?",
            condition="A",
            context_doc_ids=[],
            prompt="answer without context",
            answer="no context answer",
        ),
        RagExperimentRow(
            query_id="PLAIN-1",
            query="Is this useful?",
            condition="B",
            context_doc_ids=["MED-1", "MED-2"],
            prompt="answer with context",
            answer="Line one\nLine two",
            fidelidade=2,
            completude=1,
            utilidade=2,
            rastreabilidade=1,
            fidelidade_justificativa="supported",
            completude_justificativa="partial",
            utilidade_justificativa="useful",
            rastreabilidade_justificativa="two sources",
        ),
    ]

    written = write_rag_experiment_csv(output, rows)
    fieldnames, parsed = _read_csv(output)

    assert written == 2
    assert "condition" in fieldnames
    assert parsed[0]["context_doc_ids"] == "[]"
    assert parsed[0]["fidelidade"] == "N/A"
    assert parsed[0]["rastreabilidade"] == "N/A"
    assert json.loads(parsed[1]["context_doc_ids"]) == ["MED-1", "MED-2"]
    assert parsed[1]["answer"] == "Line one\nLine two"
    assert parsed[1]["rastreabilidade"] == "1"


def test_rag_rows_validate_condition_and_scores():
    with pytest.raises(ValueError, match="Invalid RAG condition"):
        RagExperimentRow(
            query_id="q1",
            query="query",
            condition="C",
            context_doc_ids=[],
            prompt="prompt",
            answer="answer",
        )

    with pytest.raises(ValueError, match="fidelidade must be"):
        RagExperimentRow(
            query_id="q1",
            query="query",
            condition="B",
            context_doc_ids=[],
            prompt="prompt",
            answer="answer",
            fidelidade=3,
        )
