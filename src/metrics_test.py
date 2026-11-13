import math
import random

import pytest

from metrics import (
    aggregate_metrics,
    average_precision_at_k,
    compute_metrics,
    compute_per_query_metrics,
    hit_at_k,
    ndcg_at_k,
    precision_at_k,
    recall_at_k,
)


def test_precision_recall_and_ap():
    qrels = {"d1": 2, "d2": 0, "d3": 1, "d4": 1}
    ranking = ["d2", "d1", "d5", "d3"]

    assert precision_at_k(ranking, qrels, 10) == pytest.approx(0.2)
    assert recall_at_k(ranking, qrels, 10) == pytest.approx(2 / 3)
    assert average_precision_at_k(ranking, qrels, 10) == pytest.approx((1 / 2 + 2 / 4) / 3)


def test_ap_is_truncated_at_ten_but_uses_all_relevant_documents():
    qrels = {f"d{i}": 1 for i in range(1, 13)}
    ranking = [f"d{i}" for i in range(1, 10)] + ["x", "d10", "d11", "d12"]

    assert precision_at_k(ranking, qrels, 10) == pytest.approx(0.9)
    assert recall_at_k(ranking, qrels, 10) == pytest.approx(9 / 12)
    assert average_precision_at_k(ranking, qrels, 10) == pytest.approx(9 / 12)


def test_ndcg_uses_linear_gain_and_all_judgments_for_ideal_ranking():
    qrels = {"d1": 2, "d2": 1, "d3": 0, "d4": 1}
    ranking = ["d2", "d1", "d3"]

    dcg = 1 / math.log2(2) + 2 / math.log2(3)
    idcg = 2 / math.log2(2) + 1 / math.log2(3) + 1 / math.log2(4)
    assert ndcg_at_k(ranking, qrels, 10) == pytest.approx(dcg / idcg)


def test_metrics_are_zero_without_relevant_documents():
    qrels = {"d1": 0, "d2": 0}
    ranking = ["d1", "d2"]

    assert compute_metrics(ranking, qrels) == {
        "P10": 0.0,
        "R10": 0.0,
        "AP10": 0.0,
        "NDCG10": 0.0,
    }


def test_hit_at_k():
    qrels = {"d1": 0, "d2": 2}
    assert hit_at_k(["d1", "d2"], qrels, 5) == 1.0
    assert hit_at_k(["d1"], qrels, 5) == 0.0


def test_compute_per_query_metrics_requires_every_judged_query():
    with pytest.raises(ValueError, match="Missing rankings"):
        compute_per_query_metrics({}, {"q1": {"d1": 1}})


def test_aggregate_metrics_is_a_mean_over_queries():
    per_query = {
        "q1": {"P10": 0.2, "R10": 0.4, "AP10": 0.3, "NDCG10": 0.5},
        "q2": {"P10": 0.4, "R10": 0.6, "AP10": 0.5, "NDCG10": 0.7},
    }

    assert aggregate_metrics(per_query) == {
        "P10": pytest.approx(0.3),
        "R10": pytest.approx(0.5),
        "AP10": pytest.approx(0.4),
        "NDCG10": pytest.approx(0.6),
    }


def test_matches_ir_measures_on_random_cases():
    ir_measures = pytest.importorskip("ir_measures")
    from ir_measures import AP, NDCG, P, R

    measures = [P @ 10, R @ 10, AP @ 10, NDCG @ 10]
    rng = random.Random(7)
    qrels_by_query = {}
    runs = {}
    runs_with_scores = {}

    for query_number in range(40):
        query_id = f"q{query_number}"
        doc_ids = [f"d{i}" for i in range(1, 21)]
        qrels = {doc_id: rng.choice([0, 0, 1, 2]) for doc_id in doc_ids}
        if not any(grade > 0 for grade in qrels.values()):
            qrels["d1"] = 2

        ranked = rng.sample(doc_ids, rng.randint(1, len(doc_ids)))
        qrels_by_query[query_id] = qrels
        runs[query_id] = ranked
        runs_with_scores[query_id] = {
            doc_id: float(len(ranked) - rank)
            for rank, doc_id in enumerate(ranked)
        }

    ours = aggregate_metrics(compute_per_query_metrics(runs, qrels_by_query))
    reference = ir_measures.calc_aggregate(measures, qrels_by_query, runs_with_scores)

    assert ours["P10"] == pytest.approx(reference[P @ 10])
    assert ours["R10"] == pytest.approx(reference[R @ 10])
    assert ours["AP10"] == pytest.approx(reference[AP @ 10])
    assert ours["NDCG10"] == pytest.approx(reference[NDCG @ 10])

    per_query = compute_per_query_metrics(runs, qrels_by_query)
    for query_id, qrels in qrels_by_query.items():
        reference_query = ir_measures.calc_aggregate(
            measures,
            {query_id: qrels},
            {query_id: runs_with_scores[query_id]},
        )
        assert per_query[query_id]["P10"] == pytest.approx(reference_query[P @ 10])
        assert per_query[query_id]["R10"] == pytest.approx(reference_query[R @ 10])
        assert per_query[query_id]["AP10"] == pytest.approx(reference_query[AP @ 10])
        assert per_query[query_id]["NDCG10"] == pytest.approx(reference_query[NDCG @ 10])
