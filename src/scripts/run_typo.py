from __future__ import annotations

import argparse
import json
import random

from nltk.corpus import stopwords

from ir.lexical import PipelineOptions
from ir.data import RESULTS_DIR, TYPO_EXPERIMENT_PATH, load_experiment_config
from ir.lexical import LexicalIndex
from ir.lexical import evaluate_bm25
from ir.metrics import ndcg_at_k
from ir.data import load_split
from ir.data import TypoExperimentRow, write_typo_experiment_csv
from ir.lexical import ERROR_TYPES, InjectedError, SpellingCorrector, build_dictionary, inject_query_error, tokenize_for_correction

STOPWORDS = set(stopwords.words("english"))


def ndcg_for_query(model, query: str, qrels) -> float:
    ranking = model.execute_query(query, return_scores=True)
    doc_ids = [str(doc_id) for doc_id, _ in ranking]
    return ndcg_at_k(doc_ids, qrels, 10)


def choose_injected_error(
    query: str,
    starting_type_index: int,
    vocabulary,
    rng: random.Random,
) -> InjectedError | None:
    for offset in range(len(ERROR_TYPES)):
        error_type = ERROR_TYPES[(starting_type_index + offset) % len(ERROR_TYPES)]
        injected = inject_query_error(
            query,
            error_type,
            vocabulary,
            rng=rng,
            excluded_tokens=STOPWORDS,
        )
        if injected is not None:
            return injected
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the lexical typo-correction experiment.")
    parser.add_argument("--split", default="test")
    parser.add_argument("--queries", type=int, default=10)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    config = load_experiment_config()
    selected = config["selected"]

    pipeline_name = selected["preprocessing"]
    k1 = selected["bm25_k1"]
    b = selected["bm25_b"]
    if pipeline_name is None or k1 is None or b is None:
        raise SystemExit("Run tune_lexical.py --update-config first.")

    pipeline_options = PipelineOptions[pipeline_name]
    kgram_size = selected["typo_kgram_size"] or 3
    jaccard_threshold = selected["typo_jaccard_threshold"] or 0.3
    edit_distance_threshold = selected["typo_edit_distance_threshold"] or 2

    split = load_split(args.split)
    index = LexicalIndex(split.document_texts, pipeline_options)
    baseline_run = evaluate_bm25(index, split.query_texts, split.qrels_by_query, k1, b)
    model = index.build_bm25(k1, b)

    dictionary = build_dictionary(split.document_texts)
    corrector = SpellingCorrector(
        dictionary,
        kgram_size=kgram_size,
        jaccard_threshold=jaccard_threshold,
        max_edit_distance=edit_distance_threshold,
    )

    positive_query_ids = [
        query_id
        for query_id in sorted(split.queries)
        if baseline_run.metrics_by_query[query_id]["NDCG10"] > 0
    ]

    rows: list[TypoExperimentRow] = []
    for query_id in positive_query_ids:
        if len(rows) >= args.queries:
            break

        query_text = split.queries[query_id].text
        rng = random.Random(args.seed + len(rows))
        injected = choose_injected_error(
            query_text,
            len(rows) % len(ERROR_TYPES),
            dictionary,
            rng,
        )
        if injected is None:
            continue

        corrected_query = corrector.correct_query(injected.query)
        qrels = split.qrels_by_query[query_id]

        original_ndcg = baseline_run.metrics_by_query[query_id]["NDCG10"]
        error_ndcg = ndcg_for_query(model, injected.query, qrels)
        corrected_ndcg = ndcg_for_query(model, corrected_query, qrels)

        ndcg_difference = original_ndcg - error_ndcg
        if ndcg_difference > 0:
            recovery = (corrected_ndcg - error_ndcg) / ndcg_difference
            error_reduced_performance = True
        else:
            recovery = None
            error_reduced_performance = False

        rows.append(
            TypoExperimentRow(
                query_id=query_id,
                query_original=query_text,
                query_erro=injected.query,
                query_corrigida=corrected_query,
                tipo_erro=injected.error_type,
                ndcg10_original=original_ndcg,
                ndcg10_erro=error_ndcg,
                ndcg10_corrigida=corrected_ndcg,
                recuperacao=recovery,
                erro_reduziu_desempenho=error_reduced_performance,
            )
        )
        print(
            f"{query_id} [{injected.error_type}] "
            f"{injected.original_token} -> {injected.erroneous_token}: "
            f"NDCG {original_ndcg:.4f} -> {error_ndcg:.4f} -> {corrected_ndcg:.4f}"
        )

    if len(rows) < args.queries:
        raise SystemExit(
            f"Could only build {len(rows)} typo queries, needed {args.queries}."
        )

    written = write_typo_experiment_csv(TYPO_EXPERIMENT_PATH, rows)
    original_normalized = {
        query_id: " ".join(tokenize_for_correction(split.queries[query_id].text))
        for query_id in split.queries
    }
    exact_corrections = sum(
        row.query_corrigida == original_normalized[row.query_id] for row in rows
    )
    recoveries = [row.recuperacao for row in rows if row.recuperacao is not None]

    summary = {
        "split": args.split,
        "query_count": len(rows),
        "correction_parameters": {
            "kgram_size": kgram_size,
            "jaccard_threshold": jaccard_threshold,
            "edit_distance_threshold": edit_distance_threshold,
        },
        "exact_corrections": exact_corrections,
        "mean_ndcg10_original": sum(row.ndcg10_original for row in rows) / len(rows),
        "mean_ndcg10_erro": sum(row.ndcg10_erro for row in rows) / len(rows),
        "mean_ndcg10_corrigida": sum(row.ndcg10_corrigida for row in rows) / len(rows),
        "mean_recovery": sum(recoveries) / len(recoveries) if recoveries else None,
        "queries_with_error_not_reducing_performance": sum(
            not row.erro_reduziu_desempenho for row in rows
        ),
    }
    summary_path = RESULTS_DIR / "typo_experiment_summary.json"
    with summary_path.open("w", encoding="utf-8") as output_file:
        json.dump(summary, output_file, indent=2, ensure_ascii=False)
        output_file.write("\n")

    print(f"Wrote {written} rows to {TYPO_EXPERIMENT_PATH}")
    print(f"Wrote summary to {summary_path}")
    print(json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
