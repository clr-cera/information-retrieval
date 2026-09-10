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
        self.total_documents: int = 0
        # Vector dimension (total number of terms)
        self.vector_dimension: int = 0
        # Pipeline Options
        self.options: PipelineOptions = pipeline_options
        # Index term lookup
        self.term_idx_lookup: dict[str, int] = {}
        self.idx_term_lookup: dict[int, str] = {}

    def update_total_documents(self):
        """
        Internal function for number of total documents updating
        """
        self.total_documents = len(self.posting_list.document_lengths)

    def update_vector_dimension(self):
        """
        Internal function for vector dimension updating
        """
        self.vector_dimension = len(self.posting_list.get_all_term_frequencies())

    def update_lookup(self):
        """
        Internal function for lookup dicts updating
        """
        for idx, term in enumerate(self.posting_list.get_vocabulary()):
            if term not in self.term_idx_lookup.keys(): 
                self.term_idx_lookup[term] = idx
                self.idx_term_lookup[idx] = term
    
    def execute_query(self, query: str, show_sim_score=False) -> list[int]:
        """
        Returns a ranking of document ID's
        """
        # Treating query
        query_result = get_index_terms_freq(query, self.options)
        query_terms = list(query_result.keys())
        
        # Updating
        self.update_total_documents()
        self.update_vector_dimension()
        self.update_lookup()
        
        # Variables
        query_vector = np.zeros(self.vector_dimension)
        doc_vectors = {}
        document_frequencies = self.posting_list.get_all_document_frequencies()
        ignored = {}
        
        # Remove unlisted query terms
        for term in query_terms:
            if term not in document_frequencies.keys():
                query_terms.remove(term)
                ignored[term] = query_result.pop(term, None)
        
        if len(ignored) != 0:
            print("[Vectorial Model Query] The following tokens were not found in vocabulary: ", ignored)

        # Filters only relevant docs
        for term in query_terms:
            for doc_id in self.posting_list.postings[term]:
                if doc_id not in doc_vectors: doc_vectors[doc_id] = np.zeros(self.vector_dimension)
        
        # Creates query and documents frequency vectors (crossing all the existing terms)
        for idx, term in enumerate(self.posting_list.get_vocabulary()):
            if term in query_terms: query_vector[idx] = query_result[term] 
            for doc_id in doc_vectors.keys():
                if doc_id in self.posting_list.postings[term]: doc_vectors[doc_id][self.term_idx_lookup[term]] = self.posting_list.postings[term][doc_id]

        # Calculates TF-IDF for each vector
        for idx in range(self.vector_dimension):
            term = self.idx_term_lookup[idx]
            # Query vector
            if query_vector[idx] > 0.0: query_vector[idx] = (1 + log(query_vector[idx],2)) * log(self.total_documents/document_frequencies[term],2)
            # Documents Vectors
            for doc_vector in doc_vectors.values():
                if doc_vector[idx] > 0.0: doc_vector[idx] = (1 + log(doc_vector[idx],2)) * log(self.total_documents/document_frequencies[term],2)
        
        docs_sim = {}

        # Calculates cossine similarity
        for doc_id, doc_vector in doc_vectors.items():
            docs_sim[doc_id] = np.vdot(query_vector, doc_vector) / (np.linalg.norm(query_vector) * np.linalg.norm(doc_vector))
        
        # Additional info
        if(show_sim_score):
            print("[Vectorial Model Query] Similarity scores: ", docs_sim)
        
        # Sorts dict in descending order
        docs_ranking = dict(sorted(docs_sim.items(), key=lambda item: item[1], reverse=True)).keys()

        return list(docs_ranking)
