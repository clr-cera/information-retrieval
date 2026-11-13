import numpy as np
import pytest

from semantic_retrieval import rank_documents_by_dot_product


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
