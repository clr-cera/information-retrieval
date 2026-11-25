from posting_list import PostingList
from document_processor import PipelineOptions, get_index_terms_freq
from math import log

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

    def execute_query(self, query: str, show_sim_score=False, return_scores=False) -> list[int] | list[tuple[int, float]]:
        """
        Returns a ranking of document ID's
        """
        # Treating query
        query_result = get_index_terms_freq(query, self.options)

        # Global statistics are kept by the index, so they cost O(1) here:
        # no pass over the whole collection is made at query time.
        self.update_total_documents()
        postings = self.posting_list.postings
        document_frequencies = self.posting_list.document_frequencies
        document_lengths = self.posting_list.document_lengths
        avgdl = self.posting_list.get_average_document_length()

        # Remove unlisted query terms
        query_terms = [term for term in query_result if term in postings]
        ignored = {term: frequency for term, frequency in query_result.items() if term not in postings}

        if show_sim_score and len(ignored) != 0:
            print("[Probabilistic Model Query] The following tokens were not found in vocabulary: ", ignored)

        # Calculates BM25 term at a time: only the posting lists of the query terms are visited
        docs_sim = {}
        for term in query_terms:
            df = document_frequencies[term]
            idf = log(1 + (self.total_documents - df + 0.5) / (df + 0.5))
            for doc_id, tf in postings[term].items():
                numerator = tf * (self.k + 1)
                denominator = tf + self.k * (1 - self.b + self.b * document_lengths[doc_id] / avgdl)
                docs_sim[doc_id] = docs_sim.get(doc_id, 0) + idf * numerator / denominator

        # Additional info
        if(show_sim_score):
            print("[Probabilistic Model Query] Similarity scores: ", docs_sim)
        
        # Sorts dict in descending order
        docs_ranking = dict(sorted(docs_sim.items(), key=lambda item: item[1], reverse=True))

        if return_scores:
            return list(docs_ranking.items())

        return list(docs_ranking.keys())

