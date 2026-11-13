import pytest

from hybrid import evaluate_rankings, reciprocal_rank_fusion


def test_rrf_combines_ranks_and_missing_documents():
    lexical = {"q1": [("a", 1.0), ("b", 0.9)]}
    semantic = {"q1": [("b", 1.0), ("c", 0.8)]}

    fused = reciprocal_rank_fusion(lexical, semantic, k=60)

    assert [document_id for document_id, _ in fused["q1"]] == ["b", "a", "c"]
    assert dict(fused["q1"])["b"] == pytest.approx(1 / 62 + 1 / 61)
    assert dict(fused["q1"])["a"] == pytest.approx(1 / 61)
    assert dict(fused["q1"])["c"] == pytest.approx(1 / 62)


def test_rrf_only_uses_the_configured_depth():
    lexical = {"q1": [("a", 1.0), ("b", 0.9), ("c", 0.8)]}
    semantic = {"q1": [("d", 1.0)]}

    fused = reciprocal_rank_fusion(lexical, semantic, k=10, depth=2)

    assert set(dict(fused["q1"])) == {"a", "b", "d"}


def test_rrf_requires_matching_queries_and_positive_k():
    with pytest.raises(ValueError, match="same queries"):
        reciprocal_rank_fusion({"q1": []}, {"q2": []}, k=60)

    with pytest.raises(ValueError, match="positive"):
        reciprocal_rank_fusion({"q1": []}, {"q1": []}, k=0)


def test_evaluate_rankings_returns_per_query_and_aggregated_metrics():
    rankings = {"q1": [("a", 2.0), ("b", 1.0)]}
    qrels = {"q1": {"a": 1, "b": 0}}

    metrics, aggregated = evaluate_rankings(rankings, qrels)

    assert metrics["q1"]["NDCG10"] == 1.0
    assert aggregated["NDCG10"] == 1.0
