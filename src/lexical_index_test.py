import pytest

from document_processor import PipelineOptions
from lexical_index import LexicalIndex
from lexical_retrieval import evaluate_bm25

DOCUMENTS = {
    "d1": "retrieval information retrieval",
    "d2": "information systems",
    "d3": "database systems",
}


def test_index_statistics():
    index = LexicalIndex(DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    stats = index.stats

    assert stats.document_count == 3
    assert stats.vocabulary_size == 4
    assert stats.posting_count == 6
    assert stats.average_document_length == pytest.approx(7 / 3)
    assert stats.build_time_seconds >= 0.0


def test_bm25_returns_only_documents_with_query_terms():
    index = LexicalIndex(DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    model = index.build_bm25(1.2, 0.75)

    ranking = model.execute_query("retrieval", return_scores=True)

    assert [doc_id for doc_id, _ in ranking] == ["d1"]
    assert model.execute_query("nonexistent") == []


def test_evaluate_bm25_produces_metrics_and_timings():
    index = LexicalIndex(DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    queries = {"q1": "information retrieval"}
    qrels = {"q1": {"d1": 1, "d2": 0}}

    run = evaluate_bm25(index, queries, qrels, 1.2, 0.75)

    assert run.rankings["q1"][0][0] == "d1"
    assert run.metrics_by_query["q1"] == {
        "P10": 0.1,
        "R10": 1.0,
        "AP10": 1.0,
        "NDCG10": 1.0,
    }
    assert run.aggregated_metrics == run.metrics_by_query["q1"]
    assert run.average_query_time_seconds >= 0.0
