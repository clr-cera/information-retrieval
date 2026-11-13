import pytest

from reranker import build_rerank_pairs, rerank_candidates, rerank_from_scores


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
