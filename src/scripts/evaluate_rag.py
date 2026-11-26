"""Evaluation of the RAG experiment (requirements 13 and 14).

Step "prepare" (run after run_rag.py):
- retrieval part: Precision@5, Recall@5 and Hit@5 of the 5 documents sent to the LLM;
- stage trace: for each query, the best position of a relevant document in each stage of the
  pipeline (lexical, semantic, hybrid, reranking), used in the end-to-end failure analysis;
- blind evaluation sheets: the 20 answers are shuffled (seed 42) and identified only by an item
  number, without the condition, so that the evaluators do not know which answer used RAG.
  One sheet is written per evaluator, plus a file with the 5 documents of each query (needed to
  judge fidelity) and a separate key file that maps each item back to its query and condition.

Step "merge" (run after the evaluators fill their sheets):
- reads the sheets, checks that every score is 0, 1 or 2 and has a justification;
- writes the scores of the first sheet into results/rag_experiment.csv (condition A gets
  "N/A" for traceability, as required by the assignment);
- computes the mean of each criterion per condition and, with two sheets, the agreement
  between the evaluators.
"""

from __future__ import annotations

import argparse
import csv
import json
import random
from pathlib import Path

from ir.data import (
    HYBRID_RESULTS_PATH,
    LEXICAL_RESULTS_PATH,
    RAG_EXPERIMENT_PATH,
    RERANKING_RESULTS_PATH,
    RESULTS_DIR,
    SEMANTIC_RESULTS_PATH,
    RagExperimentRow,
    load_split,
    write_rag_experiment_csv,
)
from ir.metrics import hit_at_k, precision_at_k, recall_at_k

CRITERIA = ("fidelidade", "completude", "utilidade", "rastreabilidade")
SHUFFLE_SEED = 42
CONTEXT_SIZE = 5

EVALUATION_DIR = RESULTS_DIR / "rag_avaliacao"
KEY_PATH = EVALUATION_DIR / "chave_NAO_ABRIR_antes_de_avaliar.csv"
DOCUMENTS_PATH = EVALUATION_DIR / "documentos_por_consulta.md"
RETRIEVAL_PATH = RESULTS_DIR / "rag_retrieval_metrics.csv"
TRACE_PATH = RESULTS_DIR / "rag_stage_trace.md"
SUMMARY_PATH = RESULTS_DIR / "rag_evaluation_summary.md"

SHEET_COLUMNS = ["item", "query_id", "query", "answer"]
for criterion in CRITERIA:
    SHEET_COLUMNS.append(criterion)
    SHEET_COLUMNS.append(criterion + "_justificativa")


def read_experiment_rows() -> list[dict]:
    with RAG_EXPERIMENT_PATH.open(encoding="utf-8") as csv_file:
        return list(csv.DictReader(csv_file))


def read_ranked_ids(path: Path, query_ids: list[str]) -> dict[str, list[str]]:
    ranked: dict[str, list[tuple[int, str]]] = {}
    for query_id in query_ids:
        ranked[query_id] = []
    with path.open(encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            if row["query_id"] in ranked:
                ranked[row["query_id"]].append((int(row["rank"]), row["doc_id"]))
    result: dict[str, list[str]] = {}
    for query_id, pairs in ranked.items():
        pairs.sort()
        result[query_id] = [doc_id for _, doc_id in pairs]
    return result


def best_relevant_position(ranked_ids: list[str], qrels: dict[str, int]) -> str:
    position = 0
    for doc_id in ranked_ids:
        position += 1
        if qrels.get(doc_id, 0) > 0:
            return str(position)
    return ">100"


def format_number(value: float) -> str:
    return f"{value:.4f}".replace(".", ",")


def prepare() -> None:
    split = load_split("test")
    rows = read_experiment_rows()
    query_ids = []
    for row in rows:
        if row["query_id"] not in query_ids:
            query_ids.append(row["query_id"])

    # Context documents of each query (condition B).
    context_by_query: dict[str, list[str]] = {}
    for row in rows:
        if row["condition"] == "B":
            context_by_query[row["query_id"]] = json.loads(row["context_doc_ids"])

    # 1. Retrieval metrics of the documents sent to the LLM.
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    totals = {"P5": 0.0, "R5": 0.0, "Hit5": 0.0}
    with RETRIEVAL_PATH.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(["query_id", "relevantes_nos_qrels", "relevantes_no_contexto", "P5", "R5", "Hit5"])
        for query_id in query_ids:
            qrels = split.qrels_by_query[query_id]
            context = context_by_query[query_id]
            relevant_total = sum(1 for grade in qrels.values() if grade > 0)
            relevant_in_context = sum(1 for doc_id in context if qrels.get(doc_id, 0) > 0)
            p5 = precision_at_k(context, qrels, CONTEXT_SIZE)
            r5 = recall_at_k(context, qrels, CONTEXT_SIZE)
            hit5 = hit_at_k(context, qrels, CONTEXT_SIZE)
            totals["P5"] += p5
            totals["R5"] += r5
            totals["Hit5"] += hit5
            writer.writerow([query_id, relevant_total, relevant_in_context, p5, r5, hit5])
    count = len(query_ids)
    print(f"Retrieval of the RAG context: P@5={totals['P5'] / count:.4f} "
          f"R@5={totals['R5'] / count:.4f} Hit@5={totals['Hit5'] / count:.4f}")

    # 2. Best position of a relevant document in each stage.
    stages = {
        "lexical": read_ranked_ids(LEXICAL_RESULTS_PATH, query_ids),
        "semântico": read_ranked_ids(SEMANTIC_RESULTS_PATH, query_ids),
        "híbrido": read_ranked_ids(HYBRID_RESULTS_PATH, query_ids),
        "reranking": read_ranked_ids(RERANKING_RESULTS_PATH, query_ids),
    }
    lines = ["# Rastreamento por estágio (consultas do RAG)", "",
             "Melhor posição de um documento relevante em cada estágio (>100: nenhum entre os 100 primeiros).", "",
             "| Consulta | Pergunta | Relevantes | Lexical | Semântico | Híbrido | Reranking | Relevantes no top-5 |",
             "|---|---|---|---|---|---|---|---|"]
    for query_id in query_ids:
        qrels = split.qrels_by_query[query_id]
        relevant_total = sum(1 for grade in qrels.values() if grade > 0)
        cells = [best_relevant_position(stages[stage][query_id], qrels) for stage in stages]
        in_context = []
        for doc_id in context_by_query[query_id]:
            if qrels.get(doc_id, 0) > 0:
                in_context.append(f"{doc_id} ({qrels[doc_id]})")
        context_text = ", ".join(in_context) if in_context else "nenhum"
        question = split.queries[query_id].text
        lines.append(f"| {query_id} | {question} | {relevant_total} | " + " | ".join(cells) + f" | {context_text} |")
    TRACE_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Stage trace written to {TRACE_PATH}")

    # 3. Blind evaluation sheets.
    EVALUATION_DIR.mkdir(parents=True, exist_ok=True)
    order = list(range(len(rows)))
    random.Random(SHUFFLE_SEED).shuffle(order)

    with KEY_PATH.open("w", newline="", encoding="utf-8") as key_file:
        key_writer = csv.writer(key_file)
        key_writer.writerow(["item", "query_id", "condition"])
        sheet_rows = []
        for number, row_index in enumerate(order, start=1):
            row = rows[row_index]
            item = f"R{number:02d}"
            key_writer.writerow([item, row["query_id"], row["condition"]])
            sheet_row = {"item": item, "query_id": row["query_id"], "query": row["query"], "answer": row["answer"]}
            for column in SHEET_COLUMNS[4:]:
                sheet_row[column] = ""
            sheet_rows.append(sheet_row)

    for evaluator in (1, 2):
        sheet_path = EVALUATION_DIR / f"planilha_avaliador{evaluator}.csv"
        with sheet_path.open("w", newline="", encoding="utf-8") as sheet_file:
            writer = csv.DictWriter(sheet_file, fieldnames=SHEET_COLUMNS)
            writer.writeheader()
            for sheet_row in sheet_rows:
                writer.writerow(sheet_row)
        print(f"Blind sheet written to {sheet_path}")

    # Documents of each query, to judge fidelity (the same 5 documents are used for both conditions).
    doc_lines = ["# Documentos de cada consulta (top-5 após o reranking)", "",
                 "A fidelidade das duas respostas de uma consulta é julgada contra estes mesmos 5 documentos.", ""]
    for query_id in query_ids:
        doc_lines.append(f"## {query_id}: {split.queries[query_id].text}")
        doc_lines.append("")
        for doc_id in context_by_query[query_id]:
            doc_lines.append(f"### [{doc_id}] {split.documents[doc_id].title}")
            doc_lines.append("")
            doc_lines.append(split.documents[doc_id].text)
            doc_lines.append("")
    DOCUMENTS_PATH.write_text("\n".join(doc_lines) + "\n", encoding="utf-8")
    print(f"Documents written to {DOCUMENTS_PATH}")
    print(f"Key (do not open before evaluating): {KEY_PATH}")


def read_sheet(path: Path) -> dict[str, dict]:
    """Read a filled sheet and check the scores. Returns {item: row}."""
    sheet: dict[str, dict] = {}
    problems = []
    with path.open(encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            for criterion in CRITERIA:
                value = row[criterion].strip().upper()
                if value in ("", "N/A", "NA"):
                    row[criterion] = None
                elif value in ("0", "1", "2"):
                    row[criterion] = int(value)
                else:
                    problems.append(f"{row['item']}: {criterion} = {row[criterion]!r} (use 0, 1, 2 or N/A)")
                    row[criterion] = None
                if row[criterion] is not None and not row[criterion + "_justificativa"].strip():
                    problems.append(f"{row['item']}: {criterion} has no justification")
            sheet[row["item"]] = row
    if problems:
        raise SystemExit(f"Problems in {path}:\n  " + "\n  ".join(problems))
    return sheet


def read_key() -> dict[str, tuple[str, str]]:
    key: dict[str, tuple[str, str]] = {}
    with KEY_PATH.open(encoding="utf-8") as key_file:
        for row in csv.DictReader(key_file):
            key[row["item"]] = (row["query_id"], row["condition"])
    return key


def scores_by_answer(sheet: dict[str, dict], key: dict[str, tuple[str, str]]) -> dict[tuple[str, str], dict]:
    scores = {}
    for item, row in sheet.items():
        query_id, condition = key[item]
        if condition == "A":
            row["rastreabilidade"] = None  # no sources in condition A: N/A by definition
        scores[(query_id, condition)] = row
    return scores


def merge(sheet_paths: list[Path]) -> None:
    key = read_key()
    sheets = []
    for path in sheet_paths:
        sheets.append(scores_by_answer(read_sheet(path), key))
    main_scores = sheets[0]

    rows = []
    for row in read_experiment_rows():
        scores = main_scores[(row["query_id"], row["condition"])]
        values = {}
        for criterion in CRITERIA:
            values[criterion] = scores[criterion]
            values[criterion + "_justificativa"] = scores[criterion + "_justificativa"].strip()
        if row["condition"] == "A":
            values["rastreabilidade_justificativa"] = "N/A: condição sem RAG, a resposta não recebe fontes."
        rows.append(
            RagExperimentRow(
                query_id=row["query_id"],
                query=row["query"],
                condition=row["condition"],
                context_doc_ids=json.loads(row["context_doc_ids"]),
                prompt=row["prompt"],
                answer=row["answer"],
                **values,
            )
        )
    write_rag_experiment_csv(RAG_EXPERIMENT_PATH, rows)
    print(f"Scores of {sheet_paths[0].name} written to {RAG_EXPERIMENT_PATH}")

    lines = ["# Avaliação humana do RAG", "", f"Notas de {sheet_paths[0].name}.", "",
             "| Critério | Sem RAG (A) | Com RAG (B) |", "|---|---|---|"]
    for criterion in CRITERIA:
        cells = []
        for condition in ("A", "B"):
            values = [scores[criterion] for (query_id, cond), scores in main_scores.items()
                      if cond == condition and scores[criterion] is not None]
            cells.append(format_number(sum(values) / len(values)) if values else "N/A")
        lines.append(f"| {criterion} | {cells[0]} | {cells[1]} |")

    if len(sheets) > 1:
        lines.extend(["", "## Concordância entre os avaliadores", "",
                      "| Critério | Pares avaliados | Concordância exata | Diferença média |", "|---|---|---|---|"])
        for criterion in CRITERIA:
            pairs = 0
            equal = 0
            difference = 0
            for answer_key, first in sheets[0].items():
                second = sheets[1][answer_key]
                if first[criterion] is None or second[criterion] is None:
                    continue
                pairs += 1
                if first[criterion] == second[criterion]:
                    equal += 1
                difference += abs(first[criterion] - second[criterion])
            if pairs:
                lines.append(f"| {criterion} | {pairs} | {equal / pairs:.0%} | {format_number(difference / pairs)} |")

    SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print(f"Summary written to {SUMMARY_PATH}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate the RAG experiment.")
    parser.add_argument("step", choices=["prepare", "merge"])
    parser.add_argument("--sheets", nargs="+", type=Path,
                        help="filled sheets for the merge step; the first one gives the final scores")
    args = parser.parse_args()

    if args.step == "prepare":
        prepare()
    else:
        if not args.sheets:
            raise SystemExit("Give the filled sheets with --sheets.")
        merge(args.sheets)


if __name__ == "__main__":
    main()
