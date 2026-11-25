"""Testes de ir.neural."""

from __future__ import annotations

# ============================================================================
# Origem: src/semantic_retrieval_test.py
# ============================================================================

import numpy as np
import pytest

from ir.neural import rank_documents_by_dot_product


def test_rank_documents_by_dot_product_orders_by_similarity():
    document_embeddings = np.array(
        [
            [1.0, 0.0],
            [0.0, 1.0],
            [0.6, 0.8],
        ]
    )
    document_ids = ["d1", "d2", "d3"]
    query_embedding = np.array([1.0, 0.0])

    ranking = rank_documents_by_dot_product(
        query_embedding,
        document_embeddings,
        document_ids,
        top_k=2,
    )

    assert [document_id for document_id, _ in ranking] == ["d1", "d3"]
    assert ranking[0][1] == pytest.approx(1.0)
    assert ranking[1][1] == pytest.approx(0.6)


def test_rank_documents_by_dot_product_can_return_all_documents():
    document_embeddings = np.array([[0.1], [0.9], [0.5]])
    document_ids = ["d1", "d2", "d3"]

    ranking = rank_documents_by_dot_product(
        np.array([1.0]),
        document_embeddings,
        document_ids,
    )

    assert [document_id for document_id, _ in ranking] == ["d2", "d3", "d1"]


# ============================================================================
# Origem: src/hybrid_test.py
# ============================================================================

import pytest

from ir.neural import evaluate_rankings, reciprocal_rank_fusion


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


# ============================================================================
# Origem: src/reranker_test.py
# ============================================================================

import pytest

from ir.neural import build_rerank_pairs, rerank_candidates, rerank_from_scores


def test_build_rerank_pairs_splits_top_and_tail():
    ranking = [("d1", 5.0), ("d2", 4.0), ("d3", 3.0)]
    document_texts = {"d1": "one", "d2": "two", "d3": "three"}

    top, tail, pairs = build_rerank_pairs("query", ranking, document_texts, depth=2)

    assert top == [("d1", 5.0), ("d2", 4.0)]
    assert tail == [("d3", 3.0)]
    assert pairs == [("query", "one"), ("query", "two")]


def test_rerank_from_scores_reorders_only_the_candidates():
    top = [("d1", 5.0), ("d2", 4.0), ("d3", 3.0)]
    tail = [("d4", 2.0), ("d5", 1.0)]

    ranking = rerank_from_scores(top, tail, [0.1, 0.9, 0.5])

    assert [document_id for document_id, _ in ranking] == ["d2", "d3", "d1", "d4", "d5"]
    assert ranking[-2] == ("d4", 2.0)
    assert ranking[-1] == ("d5", 1.0)


def test_rerank_candidates_only_scores_the_top_depth():
    ranking = [("d1", 5.0), ("d2", 4.0), ("d3", 3.0)]
    document_texts = {"d1": "one", "d2": "two", "d3": "three"}
    seen_pairs = []

    def predict(pairs):
        seen_pairs.extend(pairs)
        return [0.1, 0.9]

    reranked = rerank_candidates(
        "query",
        ranking,
        document_texts,
        predict,
        depth=2,
    )

    assert seen_pairs == [("query", "one"), ("query", "two")]
    assert [document_id for document_id, _ in reranked] == ["d2", "d1", "d3"]


def test_rerank_from_scores_requires_matching_lengths():
    with pytest.raises(ValueError, match="number of reranker scores"):
        rerank_from_scores([("d1", 1.0)], [], [0.1, 0.2])
