from __future__ import annotations

import random

import ir_measures
from ir_measures import AP, NDCG, P, R

from metrics import aggregate_metrics, compute_per_query_metrics
from nfcorpus_loader import load_all_splits, select_rag_query_ids
from experiment_config import RAG_QUERY_IDS


def main() -> None:
    splits = load_all_splits()
    for name, split in splits.items():
        print(
            f"{name}: {len(split.documents)} documents, "
            f"{len(split.queries)} judged queries, {len(split.qrels)} qrels"
        )

    test_split = splits["test"]
    rag_query_ids = select_rag_query_ids(test_split)
    if rag_query_ids != list(RAG_QUERY_IDS):
        raise AssertionError(f"RAG query sample mismatch: {rag_query_ids}")
    print(f"RAG queries: {rag_query_ids}")

    qrels_by_query = test_split.qrels_by_query
    corpus_doc_ids = list(test_split.documents)
    rng = random.Random(0)
    rankings = {}
    scores = {}
    for query_id, qrels in qrels_by_query.items():
        unjudged_doc_ids = [doc_id for doc_id in corpus_doc_ids if doc_id not in qrels]
        ranked_docs = list(qrels) + rng.sample(unjudged_doc_ids, 30)
        rng.shuffle(ranked_docs)
        rankings[query_id] = ranked_docs
        scores[query_id] = {
            doc_id: float(len(ranked_docs) - rank)
            for rank, doc_id in enumerate(ranked_docs)
        }

    ours = aggregate_metrics(compute_per_query_metrics(rankings, qrels_by_query))
    reference = ir_measures.calc_aggregate(
        [P @ 10, R @ 10, AP @ 10, NDCG @ 10],
        qrels_by_query,
        scores,
    )

    for metric_name, measure in (("P10", P @ 10), ("R10", R @ 10), ("AP10", AP @ 10), ("NDCG10", NDCG @ 10)):
        difference = abs(ours[metric_name] - float(reference[measure]))
        if difference > 1e-12:
            raise AssertionError(f"{metric_name} differs from ir_measures by {difference}")
        print(f"{metric_name}: {ours[metric_name]:.6f} (matches ir_measures)")

    print("Validation passed.")


if __name__ == "__main__":
    main()
