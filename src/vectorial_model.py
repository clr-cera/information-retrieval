from posting_list import PostingList
from document_processor import PipelineOptions, get_index_terms_freq
import numpy as np
from collections import Counter
from math import log, sqrt

class VectorialModel:
    def __init__(self, posting_list: PostingList, pipeline_options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming):
        """
        Initializes a Vectorial Model instance. It requires a PostingList instance.
        """
        # Uses the already created posting list 
        # Obs: (it's a reference! changes in original PostingList will change it here)
        self.posting_list: PostingList = posting_list
        # Total number of documents
        self.total_documents: int = len(posting_list.document_lengths)
        # Pipeline Options
        self.options: PipelineOptions = pipeline_options
        # Index term lookup
        self.term_idx_lookup: dict[str, int] = {}
        self.idx_term_lookup: dict[int, str] = {}
        self.vocabulary: list[str] = []

    def execute_query(self, query: str, show_sim_score=False, return_scores=False) -> list[int] | list[tuple[int, float]]:
        """
        Returns a ranking of document ID's
        """
        # Treating query
        query_result = get_index_terms_freq(query, self.options)
        query_terms = list(query_result.keys())

        # Variables
        document_frequencies = self.posting_list.get_all_document_frequencies()
        ignored = {}

        # Remove unlisted query terms
        for term in list(query_terms):
            if term not in document_frequencies.keys():
                if(show_sim_score): print(f"[Vectorial Model Query] Term removed: {term} -> {term in document_frequencies.keys()}")
                query_terms.remove(term)
                ignored[term] = query_result.pop(term, None)
        
        # Vector variables
        doc_vectors = {}
        vec_size = len(query_terms)
        query_vector = np.zeros(vec_size)

        if show_sim_score and len(ignored) != 0:
            print("[Vectorial Model Query] The following tokens were not found in vocabulary: ", ignored)
        
        # Assemble query vector
        for idx, term in enumerate(query_terms):
            query_vector[idx] = query_result[term]

        # Filters only relevant docs and assemble frequencies doc vectors
        for idx, term in enumerate(query_terms):
            for doc_id in self.posting_list.get_postings(term):
                if doc_id not in doc_vectors: doc_vectors[doc_id] = np.zeros(vec_size)
                doc_vectors[doc_id][idx] = self.posting_list.get_document_term_frequency(term, doc_id)
        
        # Calculates TF-IDF for each vector
        for idx, term in enumerate(query_terms):
            # Query vector
            if query_vector[idx] > 0.0: query_vector[idx] = (1 + log(query_vector[idx],2)) * log(self.total_documents/document_frequencies[term],2)
            # Documents Vectors
            for doc_vector in doc_vectors.values():
                if doc_vector[idx] > 0.0: doc_vector[idx] = (1 + log(doc_vector[idx],2)) * log(self.total_documents/document_frequencies[term],2)
        
        docs_sim = {}

        # Calculates cossine similarity
        for doc_id, doc_vector in doc_vectors.items():
            norm1 = np.linalg.norm(query_vector)
            norm2 = np.linalg.norm(doc_vector)
            if(norm1 == 0 or norm2 == 0): 
                docs_sim[doc_id] = -1 # -1 means a wrong document pick-up
                continue
            docs_sim[doc_id] = np.vdot(query_vector, doc_vector) / (norm1 * norm2)
        
        # Additional info
        if(show_sim_score):
            print("[Vectorial Model Query] Similarity scores: ", docs_sim)
        
        # Sorts dict in descending order
        docs_ranking = dict(sorted(docs_sim.items(), key=lambda item: item[1], reverse=True))

        if return_scores:
            return list(docs_ranking.items())

        return list(docs_ranking.keys())
