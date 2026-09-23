from ir_datasets import load
from document_processor import PipelineOptions
from experiments import Experiment, RankingModel
from get_discrepant_queries import find_best_and_worst_queries_both_models()

PREPROCESSOR_OPTIONS = [
    PipelineOptions.NoStopRemovalNoStemming,
    PipelineOptions.WithStopRemovalNoStemming,
    PipelineOptions.NoStopRemovalWithStemming,
    PipelineOptions.WithStopRemovalWithStemming
]

MODEL_OPTIONS = [
    RankingModel.Probabilistic,
    RankingModel.Vectorial
]

K_VALUES = [0.5, 1.2, 2.0]
B_VALUES = [0.0, 0.75, 1.0]

QUERY_MODIFICATIONS: dict[str, str] = {
    "1": "what similarity laws must be obeyed when constructing aeroelastic models of aircraft .",
    "2": "what are the aeroelastic problems associated with flight of high speed aircraft .",
    "3": "what problems of transient heat conduction in composite slabs have been solved so far .",
    "5": "what chemical kinetic mechanism is applicable to hypersonic aerodynamic problems .",
    "12": "how can the aerodynamic performance of ground effect machines be calculated .",
}

def main():
    dataset = load("cranfield")
    queries = [query for query in dataset.queries_iter()]
    docs = [doc for doc in dataset.docs_iter()]
    qrels = [qrel for qrel in dataset.qrels_iter()]

    queries_by_id = {query.query_id: query for query in queries}
    qrels_by_query: dict[str, list] = {}
    for qrel in qrels:
        qrels_by_query.setdefault(qrel.query_id, []).append(qrel)

    for original_query_id, modified_text in QUERY_MODIFICATIONS.items():
        modified_query_id = f"{original_query_id}_mod"
        queries.append(queries_by_id[original_query_id]._replace(query_id=modified_query_id, text=modified_text))
        for qrel in qrels_by_query[original_query_id]:
            qrels.append(qrel._replace(query_id=modified_query_id))

    for pipeline_option in PREPROCESSOR_OPTIONS:
        for model_option in MODEL_OPTIONS:
            print(f"Running experiment with pipeline option: {pipeline_option} and model option: {model_option}")
            if model_option == RankingModel.Probabilistic:
                for k in K_VALUES:
                    for b in B_VALUES:
                        print(f"Running experiment with k={k} and b={b}")
                        experiment = Experiment(pipeline_option, model_option, k, b, queries, docs, qrels)
                        experiment.run()
            else:
                experiment = Experiment(pipeline_option, model_option, 0, 0, queries, docs, qrels)
                experiment.run()

    find_best_and_worst_queries_both_models()

if __name__ == "__main__":
    main()
