"""RAG experiment (requirements 11 and 12): the same LLM answers the 10 fixed test questions
without RAG (condition A) and with RAG (condition B, top-5 documents after reranking).

The top-5 documents are read from results/results_reranking.csv, the final ranking of the
retrieval pipeline (hybrid RRF + cross-encoder). Run run_retrieval_pipeline.py first.

Outputs:
- results/rag_experiment.csv: one row per (query, condition), with the prompt, the context
  documents and the answer. The four scores stay "N/A" until the human evaluation is merged
  by evaluate_rag.py;
- results/rag_generations.json: time and number of tokens of each answer.

The answers are written after each call, so an interrupted run keeps what was already done.
"""

from __future__ import annotations

import argparse
import csv
import json

from ir.data import (
    RAG_EXPERIMENT_PATH,
    RAG_QUERY_IDS,
    RERANKING_RESULTS_PATH,
    RESULTS_DIR,
    RagExperimentRow,
    load_experiment_config,
    load_split,
    select_rag_query_ids,
    write_rag_experiment_csv,
)
from ir.rag import ask_llm, build_prompt_with_context, build_prompt_without_context

CONTEXT_SIZE = 5
GENERATIONS_PATH = RESULTS_DIR / "rag_generations.json"


def read_top_documents(path, query_ids, size: int) -> dict[str, list[str]]:
    """Read the first `size` documents of each query from a results_*.csv file."""
    top_documents: dict[str, list[tuple[int, str]]] = {}
    for query_id in query_ids:
        top_documents[query_id] = []

    with path.open(encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            query_id = row["query_id"]
            rank = int(row["rank"])
            if query_id in top_documents and rank <= size:
                top_documents[query_id].append((rank, row["doc_id"]))

    ordered: dict[str, list[str]] = {}
    for query_id, documents in top_documents.items():
        documents.sort()
        ordered[query_id] = []
        for _, doc_id in documents:
            ordered[query_id].append(doc_id)
    return ordered


def save_progress(rows: list[RagExperimentRow], generations: list[dict]) -> None:
    write_rag_experiment_csv(RAG_EXPERIMENT_PATH, rows)
    with GENERATIONS_PATH.open("w", encoding="utf-8") as output_file:
        json.dump(generations, output_file, indent=2, ensure_ascii=False)
        output_file.write("\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the RAG experiment (without RAG x with RAG).")
    parser.add_argument("--queries", type=int, default=len(RAG_QUERY_IDS),
                        help="number of queries to run (useful for a quick test)")
    args = parser.parse_args()

    selected = load_experiment_config()["selected"]
    model = selected["llm"]
    temperature = selected["llm_temperature"]
    max_tokens = selected["llm_max_tokens"]
    if model is None or max_tokens is None:
        raise SystemExit("Set llm and llm_max_tokens in config/tp2_experiment.json first.")

    split = load_split("test")

    # The sample must be the one defined in the assignment.
    if select_rag_query_ids(split) != list(RAG_QUERY_IDS):
        raise SystemExit("The RAG query sample does not match the assignment.")
    query_ids = list(RAG_QUERY_IDS)[: args.queries]

    top_documents = read_top_documents(RERANKING_RESULTS_PATH, query_ids, CONTEXT_SIZE)

    rows: list[RagExperimentRow] = []
    generations: list[dict] = []
    for number, query_id in enumerate(query_ids, start=1):
        question = split.queries[query_id].text
        context_ids = top_documents[query_id]
        if len(context_ids) != CONTEXT_SIZE:
            raise SystemExit(f"{query_id} has {len(context_ids)} reranked documents, expected {CONTEXT_SIZE}.")

        documents = []
        for doc_id in context_ids:
            documents.append((doc_id, split.documents[doc_id].searchable_text))

        conditions = (
            ("A", build_prompt_without_context(question), []),
            ("B", build_prompt_with_context(question, documents), context_ids),
        )
        for condition, prompt, condition_context in conditions:
            print(f"[{number}/{len(query_ids)}] {query_id} condition {condition}: {question}")
            answer = ask_llm(prompt, model, temperature, max_tokens)
            print(f"    {answer.seconds:.1f} s, {answer.generated_tokens} tokens generated, "
                  f"finished={answer.finished}")

            rows.append(
                RagExperimentRow(
                    query_id=query_id,
                    query=question,
                    condition=condition,
                    context_doc_ids=condition_context,
                    prompt=prompt,
                    answer=answer.text,
                )
            )
            generations.append(
                {
                    "query_id": query_id,
                    "condition": condition,
                    "seconds": answer.seconds,
                    "prompt_tokens": answer.prompt_tokens,
                    "generated_tokens": answer.generated_tokens,
                    "finished": answer.finished,
                }
            )
            save_progress(rows, generations)

    print(f"Wrote {len(rows)} rows to {RAG_EXPERIMENT_PATH}")
    print(f"Wrote generation statistics to {GENERATIONS_PATH}")


if __name__ == "__main__":
    main()
