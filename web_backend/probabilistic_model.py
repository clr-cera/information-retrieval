from posting_list import PostingList
from document_processor import PipelineOptions, get_index_terms_freq
from math import log, sqrt
import numpy as np

class ProbabilisticModel:
    def __init__(self, posting_list: PostingList, pipeline_options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming, k: float = 1.2, b: float = 0.75):
        """
        Initializes a Probailistic Model (BM25) instance. It requires a PostingList instance.
        """
        # Uses the already created posting list
        # Obs: (it's a reference! changes in original PostingList will change it here)
        self.posting_list: PostingList = posting_list
        # Total number of documents
        self.total_documents: int = 0
        # Pipeline Options
        self.options: PipelineOptions = pipeline_options
        # Global parameters
        self.k = k
        self.b = b

    def update_total_documents(self):
        """
        Internal function for number of total documents updating
        """
        self.total_documents = len(self.posting_list.document_lengths)

    def execute_query(self, query: str, show_sim_score=False, return_scores=False) -> list[int] | list[tuple[int,tuple[float, dict[str, float]]]]:
        """
        Returns a ranking of document ID's
        """
        # Treating query
        query_result = get_index_terms_freq(query, self.options)
        query_terms = list(query_result.keys())

        # Updating
        self.update_total_documents()

        # Variables
        doc_vectors = {}
        docs_sim = {}
        document_frequencies = self.posting_list.get_all_document_frequencies()
        document_lengths = self.posting_list.get_all_document_lengths()
        ignored = {}
        query_terms_score = {}

        # Remove unlisted query terms
        for term in list(query_terms):
            if term not in document_frequencies.keys():
                query_terms.remove(term)
                ignored[term] = query_result.pop(term, None)
        
        # Getting terms number and idf
        terms_number = len(query_terms)
        idf_vector = np.zeros(terms_number)

        if show_sim_score and len(ignored) != 0:
            print("[Probabilistic Model Query] The following tokens were not found in vocabulary: ", ignored)

        for idx, term in enumerate(query_terms):
            # Creates documents frequency vectors
            for doc_id in self.posting_list.postings[term]:
                if doc_id not in doc_vectors: doc_vectors[doc_id] = np.zeros(terms_number)
                doc_vectors[doc_id][idx] = self.posting_list.postings[term][doc_id]

            # Creates IDF vector
            idf_vector[idx] = log(1 + (self.total_documents - document_frequencies[term] + 0.5)/(document_frequencies[term] + 0.5))

        # Calculates Average Document length
        avgdl = sum(document_lengths.values()) / self.total_documents

        # Calculates BIM25
        for doc_id, doc_vector in doc_vectors.items():
            terms_score = {}
            if(doc_id) not in docs_sim.keys(): docs_sim[doc_id] = 0
            for idx in range(terms_number):
                numerator = doc_vector[idx] * (self.k + 1)
                denominator = doc_vector[idx] + self.k * (1 - self.b + self.b * document_lengths[doc_id] / avgdl)
                docs_sim[doc_id] += idf_vector[idx] * numerator / denominator
                terms_score[query_terms[idx]] = docs_sim[doc_id]
            terms_score = dict(
                sorted(terms_score.items(), key=lambda item: item[1], reverse=True)[:10 if len(terms_score) >= 10 else len(terms_score)]
            )
            query_terms_score[doc_id] = terms_score

        # Additional info
        if(show_sim_score):
            print("[Probabilistic Model Query] Similarity scores: ", docs_sim)

        # Sorts dict in descending order
        docs_ranking = dict(sorted(docs_sim.items(), key=lambda item: item[1], reverse=True))

        if return_scores:
            docs_ranking = {id: (score, query_terms_score[id]) for id,score in docs_ranking.items()}
            return list(docs_ranking.items())

        return list(docs_ranking.keys())
