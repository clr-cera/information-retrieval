import re
import ast
from pathlib import Path
from ir_datasets import load
import math

RESULTS_DIR = Path("result")

def find_best_and_worst_queries_both_models():
    """
    Finds top queries where Probabilistic > Vectorial, Vectorial > Probabilistic,
    and queries where both models performed the worst overall.
    """
    prob_metrics_file = RESULTS_DIR / "metrics_WithStopRemovalWithStemming_Probabilistic_k1.2_b1.0.txt"
    vect_metrics_file = RESULTS_DIR / "metrics_WithStopRemovalWithStemming_Vectorial.txt"
    
    prob_docs_file = RESULTS_DIR / "top_10_docs_WithStopRemovalWithStemming_Probabilistic_k1.2_b1.0.txt"
    vect_docs_file = RESULTS_DIR / "top_10_docs_WithStopRemovalWithStemming_Vectorial.txt"

    def parse_query_maps(file_path):
        query_maps = {}
        if not file_path.exists():
            return query_maps
        with file_path.open('r') as f:
            for line in f:
                # Updated to capture only the query number digits
                match = re.match(r'Query\s+(\d+):\s*\{.*[\'\"]map[\'\"]:\s*([0-9]+\.[0-9]+)', line)
                if match:
                    query_maps[match.group(1)] = float(match.group(2))
        return query_maps

    def parse_top_docs(file_path):
        query_docs = {}
        if not file_path.exists():
            return query_docs
        with file_path.open('r') as f:
            for line in f:
                # Updated to capture only the query number digits
                match = re.match(r'Query\s+(\d+):\s*(.+)', line)
                if match:
                    try:
                        query_docs[match.group(1)] = ast.literal_eval(match.group(2))
                    except Exception:
                        continue
        return query_docs

    prob_maps = parse_query_maps(prob_metrics_file)
    vect_maps = parse_query_maps(vect_metrics_file)
    prob_docs = parse_top_docs(prob_docs_file)
    vect_docs = parse_top_docs(vect_docs_file)

    common_queries = set(prob_maps.keys()).intersection(set(vect_maps.keys()))

    differences = []
    for q in common_queries:
        p_val = prob_maps[q]
        v_val = vect_maps[q]
        diff = p_val - v_val  
        differences.append((q, diff, p_val, v_val))

    # Sorts
    prob_better = sorted(differences, key=lambda x: x[1], reverse=True)
    vect_better = sorted(differences, key=lambda x: x[1])
    
    # Define "worst in both" by sorting combined performance (e.g., average MAP or sum of MAPs) in ascending order
    both_worst_sorted = sorted(differences, key=lambda x: (x[2] + x[3]))

    better_ids = []
    worst_ids = []
    both_worst_ids = []
    detailed_results = {}

    # Top 2 Probabilistic > Vectorial
    for q, diff, p, v in prob_better[:2]:
        better_ids.append(q)
        detailed_results[q] = {"prob_map": p, "vect_map": v, "prob_docs": prob_docs.get(q, []), "vect_docs": vect_docs.get(q, [])}

    # Top 2 Vectorial > Probabilistic
    for q, diff, p, v in vect_better[:2]:
        worst_ids.append(q)
        detailed_results[q] = {"prob_map": p, "vect_map": v, "prob_docs": prob_docs.get(q, []), "vect_docs": vect_docs.get(q, [])}

    # Top 2 Lowest Combined Performance across both models
    for q, diff, p, v in both_worst_sorted[:2]:
        both_worst_ids.append(q)
        detailed_results[q] = {"prob_map": p, "vect_map": v, "prob_docs": prob_docs.get(q, []), "vect_docs": vect_docs.get(q, [])}

    # NOW looking INTO DATASET
    dataset = load("cranfield")
    queries = [query for query in dataset.queries_iter()]
    docs = [doc for doc in dataset.docs_iter()]
    qrels = [qrel for qrel in dataset.qrels_iter()]

    queries_by_id = {query.query_id: query for query in queries}
    docs_by_id = {doc.doc_id: doc for doc in docs}
    qrels_by_query: dict[str, list] = {}
    for qrel in qrels:
        qrels_by_query.setdefault(qrel.query_id, []).append(qrel)

    # Save top 10 documents per query, with scores and relevance flags, to a file
    relevant_docs_by_query: dict[int, set[int]] = {}
    for qrel in qrels:
            if qrel.relevance > 0:
                relevant_docs_by_query.setdefault(qrel.query_id, set()).add(qrel.doc_id)

    with open(RESULTS_DIR / f"best_queries_Probabilistic.txt", "w") as f:
        for id in better_ids:
            query = queries_by_id.get(id.replace("Query ",""),0)
            f.write(f"\nQuery {id}: `{query.text}`\n")
            f.write(f"\n- Prob MAP: {detailed_results[id]["prob_map"]}\n- Vec MAP: {detailed_results[id]["vect_map"]}\n")
            doc_ids = [t[0] for t in detailed_results[id]["prob_docs"]]
            for idx, doc_id in enumerate(doc_ids):
                if idx == 5: break
                doc = docs_by_id.get(doc_id,0)
                relevant_docs = relevant_docs_by_query.get(id, set()) # Uses query id
                f.write(f"\n\n{idx+1}. Doc {doc_id} [{"RELEVANT" if doc_id in relevant_docs else "IRRELEVANT"}]\n```\n{doc.text}\n```")
            f.write("\n\n#divider()\n")
    
    with open(RESULTS_DIR / f"best_queries_Vectorial.txt", "w") as f:
        for id in worst_ids:
            query = queries_by_id.get(id.replace("Query ",""),0)
            f.write(f"\nQuery {id}: `{query.text}`\n")
            f.write(f"\n- Prob MAP: {detailed_results[id]["prob_map"]}\n- Vec MAP: {detailed_results[id]["vect_map"]}")
            doc_ids = [t[0] for t in detailed_results[id]["vect_docs"]]
            for idx, doc_id in enumerate(doc_ids):
                if idx == 5: break
                doc = docs_by_id.get(doc_id,0)
                relevant_docs = relevant_docs_by_query.get(id, set()) # Uses query id
                f.write(f"\n\n{idx+1}. Doc {doc_id} [{"RELEVANT" if doc_id in relevant_docs else "IRRELEVANT"}]\n```\n{doc.text}\n```")
            f.write("\n\n#divider()\n")

    with open(RESULTS_DIR / f"worst_queries.txt", "w") as f:
        for id in both_worst_ids:
            query = queries_by_id.get(id.replace("Query ",""),0)
            f.write(f"\nQuery {id}: `{query.text}`\n")
            f.write(f"\n- Prob MAP: {detailed_results[id]["prob_map"]}\n- Vec MAP: {detailed_results[id]["vect_map"]}\n")
            doc_ids = [t[0] for t in detailed_results[id]["prob_docs"]]
            for idx, doc_id in enumerate(doc_ids):
                if idx == 5: break
                doc = docs_by_id.get(doc_id,0)
                relevant_docs = relevant_docs_by_query.get(id, set()) # Uses query id
                f.write(f"\n\n{idx+1}. Doc {doc_id} [{"RELEVANT" if doc_id in relevant_docs else "IRRELEVANT"}]\n```\n{doc.text}\n```")
            f.write("\n\n#divider()\n")
