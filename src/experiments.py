from document_processor import PipelineOptions
from enum import Enum
from pathlib import Path
from posting_list import PostingList
from probabilistic_model import ProbabilisticModel
from vectorial_model import VectorialModel

RESULTS_DIR = Path("result")

class RankingModel(Enum):
    Probabilistic = 1
    Vectorial = 2

    def __str__(self):
        return self.name
    def __repr__(self):
        return self.name
    def __eq__(self, other):
        if isinstance(other, RankingModel):
            return self.value == other.value
        return NotImplemented

class Experiment:
    def __init__(self, pipeline_options: PipelineOptions, ranking_model: RankingModel, k: float, b: float, queries, docs, qrels):
        self.pipeline_options = pipeline_options
        self.ranking_model = ranking_model
        self.queries = queries
        self.docs = docs
        self.qrels = qrels
        self.k = k
        self.b = b
        self.relevant_docs_by_query: dict[int, set[int]] = {}
        for qrel in self.qrels:
            if qrel.relevance > 0:
                self.relevant_docs_by_query.setdefault(qrel.query_id, set()).add(qrel.doc_id)

    def run(self):
        """
        Runs the experiment with the specified pipeline options and ranking model.
        """
        print(f"Running experiment with pipeline options: {self.pipeline_options} and ranking model: {self.ranking_model}")
        experiment_identifier = f"{self.pipeline_options}_{self.ranking_model}"
        if self.ranking_model == RankingModel.Probabilistic:
            experiment_identifier += f"_k{self.k}_b{self.b}"

        RESULTS_DIR.mkdir(parents=True, exist_ok=True)

        # Create PostingList
        posting_list = PostingList(self.pipeline_options)
        docs_for_posting_list: dict[int, str] = {doc.doc_id: doc.text for doc in self.docs}
        posting_list.add_documents(docs_for_posting_list)

        queries_for_experiment: dict[int, str] = {query.query_id: query.text for query in self.queries}

        model = None
        # Create model
        if self.ranking_model == RankingModel.Probabilistic:
            model = ProbabilisticModel(posting_list, self.pipeline_options, self.k, self.b)
        elif self.ranking_model == RankingModel.Vectorial:
            model = VectorialModel(posting_list, self.pipeline_options)
        else:
            raise ValueError(f"Invalid ranking model: {self.ranking_model}")

        # Execute queries
        metrics_per_query = {}
        top_10_docs_per_query = {}
        for query_id, query_text in queries_for_experiment.items():
            ranked_docs_metrics: list[tuple[int, float]] = model.execute_query(query_text, return_scores=True)
            ranked_docs = [doc_id for doc_id, _ in ranked_docs_metrics]
            metrics = self.calculate_metrics(ranked_docs, query_id)
            metrics_per_query[query_id] = metrics
            relevant_docs = self.relevant_docs_by_query.get(query_id, set())
            top_10_docs_per_query[query_id] = [
                (doc_id, float(score), 1 if doc_id in relevant_docs else 0)
                for doc_id, score in ranked_docs_metrics[:10]
            ]

        # Save metrics to a file
        with open(RESULTS_DIR / f"metrics_{experiment_identifier}.txt", "w") as f:
            for query_id, metrics in metrics_per_query.items():
                f.write(f"Query {query_id}: {metrics}\n")

        # Save top 10 documents per query, with scores and relevance flags, to a file
        with open(RESULTS_DIR / f"top_10_docs_{experiment_identifier}.txt", "w") as f:
            for query_id, top_docs in top_10_docs_per_query.items():
                f.write(f"Query {query_id}: {top_docs}\n")

        agg_metrics = {
            "precision@10": sum(m["precision@10"] for m in metrics_per_query.values()) / len(metrics_per_query),
            "recall@10": sum(m["recall@10"] for m in metrics_per_query.values()) / len(metrics_per_query),
            "map": sum(m["map"] for m in metrics_per_query.values()) / len(metrics_per_query),
        }
        # Save aggregated metrics to a file
        with open(RESULTS_DIR / f"metrics_{experiment_identifier}_aggregated.txt", "w") as f:
            for metric, value in agg_metrics.items():
                f.write(f"{metric}: {value}\n")

        print(f"Experiment {experiment_identifier} completed. Results saved to {RESULTS_DIR}/")

    def calculate_metrics(self, ranked_docs: list[int], query_id: int) -> dict[str, float]:
        """
        Calculates evaluation metrics for the ranked documents of a specific query.
        """
        relevant_docs = self.relevant_docs_by_query.get(query_id, set())

        # Precision@10
        top_k = 10
        top_k_docs = ranked_docs[:top_k]
        top_k_relevant_docs = relevant_docs & set(top_k_docs)
        precision_at_10 = len(top_k_relevant_docs) / top_k if top_k > 0 else 0.0
        # Recall@10
        recall_at_10 = len(top_k_relevant_docs) / len(relevant_docs) if len(relevant_docs) > 0 else 0.0

        # Mean Average Precision (MAP)
        average_precision = 0.0
        num_relevant_docs = 0
        for rank, doc_id in enumerate(ranked_docs, start=1):
            if doc_id in relevant_docs:
                num_relevant_docs += 1
                average_precision += num_relevant_docs / rank
        mean_average_precision = average_precision / len(relevant_docs) if len(relevant_docs) > 0 else 0.0


        return {
            "precision@10": precision_at_10,
            "recall@10": recall_at_10,
            "map": mean_average_precision,
        }