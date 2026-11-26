"""Check and summarize the typo-correction experiment (requirement 4).

Reads results/typo_experiment.csv (written by run_typo.py) and:

1. checks the rules of the assignment for every query:
   - the original query has NDCG@10 > 0;
   - exactly one token was changed, and the new token is not in the dictionary;
   - the original token is in the dictionary (terms before stemming);
2. reports the error types used, the correction accuracy and the recovery;
3. for the queries where the error did not reduce NDCG@10, shows the top-5
   documents of the original query and of the query with the error, so the
   report can explain the difference with real data.

The output is a Markdown file (results/typo_analysis.md) and the same text
is printed on the screen.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from ir.data import RESULTS_DIR, TYPO_EXPERIMENT_PATH, load_experiment_config, load_split
from ir.lexical import (
    ERROR_TYPES,
    LexicalIndex,
    PipelineOptions,
    build_dictionary,
    get_index_terms_freq,
    levenshtein_distance,
    tokenize_for_correction,
)

ANALYSIS_PATH = RESULTS_DIR / "typo_analysis.md"
TOP_K_TO_SHOW = 5


def read_experiment_rows(path: Path) -> list[dict]:
    """Read the CSV written by run_typo.py."""
    rows = []
    with path.open(encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        for row in reader:
            rows.append(row)
    return rows


def find_changed_tokens(original_tokens: list[str], other_tokens: list[str]) -> list[tuple[str, str]]:
    """Return the (original, changed) pairs of tokens that differ between two queries.

    The error injection never adds or removes tokens, so both lists have the same size.
    """
    if len(original_tokens) != len(other_tokens):
        raise ValueError(f"Token lists have different sizes: {original_tokens} x {other_tokens}")

    changed = []
    for original_token, other_token in zip(original_tokens, other_tokens):
        if original_token != other_token:
            changed.append((original_token, other_token))
    return changed


def format_number(value: float) -> str:
    """Format a metric with 4 decimals, using a comma as in the report."""
    return f"{value:.4f}".replace(".", ",")


def check_rows(rows: list[dict], dictionary) -> tuple[list[str], list[dict]]:
    """Check the assignment rules for each row.

    Returns the list of problems found (empty when everything is fine) and a list
    with the details of each query, used to build the tables.
    """
    problems = []
    details = []

    for row in rows:
        query_id = row["query_id"]
        original_tokens = tokenize_for_correction(row["query_original"])
        error_tokens = row["query_erro"].split()
        corrected_tokens = row["query_corrigida"].split()

        ndcg_original = float(row["NDCG10_original"])
        ndcg_error = float(row["NDCG10_erro"])
        ndcg_corrected = float(row["NDCG10_corrigida"])

        # Rule (iii): the original query must have NDCG@10 greater than zero.
        if ndcg_original <= 0:
            problems.append(f"{query_id}: original NDCG@10 is not greater than zero")

        # Exactly one token must have been changed by the error.
        error_changes = find_changed_tokens(original_tokens, error_tokens)
        if len(error_changes) != 1:
            problems.append(f"{query_id}: expected 1 changed token, found {len(error_changes)}")
            continue
        original_token, wrong_token = error_changes[0]

        # Rule (ii): the wrong token must not exist in the dictionary.
        if wrong_token in dictionary:
            problems.append(f"{query_id}: '{wrong_token}' is a valid word of the dictionary")

        # Rule (i): the dictionary is made of the terms before stemming,
        # so the original token must be there.
        if original_token not in dictionary:
            problems.append(f"{query_id}: original token '{original_token}' is not in the dictionary")

        # The correction must not change any other token of the query.
        correction_changes = find_changed_tokens(original_tokens, corrected_tokens)
        wrong_corrections = []
        for original, corrected in correction_changes:
            if original != original_token:
                wrong_corrections.append(f"{original} -> {corrected}")

        correction_is_exact = len(correction_changes) == 0

        details.append(
            {
                "query_id": query_id,
                "query_original": row["query_original"],
                "query_erro": row["query_erro"],
                "original_token": original_token,
                "wrong_token": wrong_token,
                "error_type": row["tipo_erro"],
                "edit_distance": levenshtein_distance(original_token, wrong_token),
                "correction_is_exact": correction_is_exact,
                "wrong_corrections": wrong_corrections,
                "ndcg_original": ndcg_original,
                "ndcg_error": ndcg_error,
                "ndcg_corrected": ndcg_corrected,
                "error_reduced": ndcg_original - ndcg_error > 0,
                "recovery": row["recuperacao"],
            }
        )

    return problems, details


def build_summary(details: list[dict]) -> list[str]:
    """Build the Markdown lines with the per-query table and the averages."""
    lines = []
    lines.append("## Consultas do experimento")
    lines.append("")
    lines.append("| Consulta | Texto original | Erro | Tipo | NDCG@10 original | com erro | corrigida | Recuperação |")
    lines.append("|---|---|---|---|---|---|---|---|")

    for item in details:
        if item["error_reduced"]:
            recovery_text = format_number(float(item["recovery"]))
        else:
            recovery_text = "erro não reduziu o NDCG@10"
        lines.append(
            f"| {item['query_id']} | {item['query_original']} | {item['original_token']} → {item['wrong_token']} "
            f"| {item['error_type']} | {format_number(item['ndcg_original'])} | {format_number(item['ndcg_error'])} "
            f"| {format_number(item['ndcg_corrected'])} | {recovery_text} |"
        )

    total = len(details)
    sum_original = 0.0
    sum_error = 0.0
    sum_corrected = 0.0
    exact_corrections = 0
    recoveries = []
    for item in details:
        sum_original += item["ndcg_original"]
        sum_error += item["ndcg_error"]
        sum_corrected += item["ndcg_corrected"]
        if item["correction_is_exact"]:
            exact_corrections += 1
        if item["error_reduced"]:
            recoveries.append(float(item["recovery"]))

    lines.append("")
    lines.append("## Resumo")
    lines.append("")
    lines.append(f"- Consultas: {total}")
    lines.append(f"- NDCG@10 médio: original {format_number(sum_original / total)}, "
                 f"com erro {format_number(sum_error / total)}, corrigida {format_number(sum_corrected / total)}")
    lines.append(f"- Correções que voltaram exatamente à consulta original: {exact_corrections} de {total}")
    lines.append(f"- Consultas em que o erro reduziu o NDCG@10: {len(recoveries)} de {total}")
    if recoveries:
        mean_recovery = sum(recoveries) / len(recoveries)
        lines.append(f"- Recuperação média nessas consultas: {format_number(mean_recovery)}")

    lines.append("")
    lines.append("## Tipos de erro")
    lines.append("")
    for error_type in ERROR_TYPES:
        count = 0
        for item in details:
            if item["error_type"] == error_type:
                count += 1
        lines.append(f"- {error_type}: {count}")

    distances = []
    for item in details:
        distances.append(item["edit_distance"])
    lines.append(f"- Distância de edição entre o termo original e o termo com erro: "
                 f"mínima {min(distances)}, máxima {max(distances)}")
    return lines


def show_top_documents(details: list[dict], split, config: dict) -> list[str]:
    """For the queries where the error did not reduce NDCG@10, compare the top documents."""
    selected = config["selected"]
    pipeline_options = PipelineOptions[selected["preprocessing"]]
    index = LexicalIndex(split.document_texts, pipeline_options)
    model = index.build_bm25(selected["bm25_k1"], selected["bm25_b"])

    lines = []
    lines.append("## Consultas em que o erro não reduziu o NDCG@10")
    lines.append("")

    for item in details:
        if item["error_reduced"]:
            continue

        query_id = item["query_id"]
        qrels = split.qrels_by_query[query_id]
        relevant_count = 0
        for grade in qrels.values():
            if grade > 0:
                relevant_count += 1

        original_query = item["query_original"]
        error_query = item["query_erro"]

        lines.append(f"### {query_id}: \"{original_query}\" ({relevant_count} documentos relevantes nos qrels)")
        lines.append("")

        # Document frequency of each stemmed term of the original query.
        lines.append("Termos da consulta original no índice (após o pré-processamento):")
        lines.append("")
        for term in get_index_terms_freq(original_query, pipeline_options):
            document_frequency = index.posting_list.get_document_frequency(term)
            lines.append(f"- `{term}`: presente em {document_frequency} documentos")
        lines.append("")

        for label, query_text in (("original", original_query), ("com erro", error_query)):
            ranking = model.execute_query(query_text, return_scores=True)
            lines.append(f"Top-{TOP_K_TO_SHOW} da consulta {label} (`{query_text}`):")
            lines.append("")
            lines.append("| Posição | Documento | Score BM25 | Grau de relevância |")
            lines.append("|---|---|---|---|")
            position = 0
            for doc_id, score in ranking[:TOP_K_TO_SHOW]:
                position += 1
                grade = qrels.get(doc_id, 0)
                lines.append(f"| {position} | {doc_id} | {format_number(score)} | {grade} |")
            lines.append("")

    return lines


def main() -> None:
    parser = argparse.ArgumentParser(description="Check and summarize the typo-correction experiment.")
    parser.add_argument("--split", default="test")
    args = parser.parse_args()

    if not TYPO_EXPERIMENT_PATH.exists():
        raise SystemExit(f"{TYPO_EXPERIMENT_PATH} not found. Run run_typo.py first.")

    config = load_experiment_config()
    split = load_split(args.split)
    dictionary = build_dictionary(split.document_texts)
    rows = read_experiment_rows(TYPO_EXPERIMENT_PATH)

    problems, details = check_rows(rows, dictionary)

    lines = ["# Experimento de tolerância a erros", ""]
    lines.append(f"Dicionário da correção: {len(dictionary)} termos (tokenização e minúsculas, antes do stemming).")
    lines.append("")
    lines.append("## Verificação das regras do enunciado")
    lines.append("")
    if problems:
        for problem in problems:
            lines.append(f"- PROBLEMA: {problem}")
    else:
        lines.append("- Todas as consultas têm NDCG@10 original maior que zero.")
        lines.append("- Cada consulta tem exatamente um termo alterado, e o termo com erro não existe no dicionário.")
        lines.append("- O termo original de cada consulta está no dicionário (termos antes do stemming).")
    lines.append("")

    lines.extend(build_summary(details))
    lines.append("")
    lines.extend(show_top_documents(details, split, config))

    text = "\n".join(lines) + "\n"
    ANALYSIS_PATH.write_text(text, encoding="utf-8")
    print(text)
    print(f"Analysis written to {ANALYSIS_PATH}")

    if problems:
        raise SystemExit(f"{len(problems)} problem(s) found in the experiment.")


if __name__ == "__main__":
    main()
