from document_processor import get_index_terms_freq, PipelineOptions
class PostingList:
    """
    A class to represent a posting list (Inverted Index).
    """

    def __init__(self, pipeline_options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming):
        """
        Initializes a PostingList instance.
        """
        # The postings dictionary maps terms to a dictionary of document IDs that maps to the frequency of the term in the document.
        self.postings: dict[str, dict[int, int]] = {}
        # The term_frequencies dictionary maps terms to their overall frequency in the posting list (tf).
        self.term_frequencies: dict[str, int] = {}
        # The document_frequencies dictionary maps terms to the number of documents in which they appear (df).
        self.document_frequencies: dict[str, int] = {}
        # The document_lengths dictionary maps document IDs to the number of unique terms in the document.
        self.document_lengths: dict[int, int] = {}

        self.pipeline_options: PipelineOptions = pipeline_options

    def _add_posting(self, term: str, frequency: int, doc_id: int):
        """
        Adds a posting for a term in a specific document.
        """
        # Add term to vocabulary if it doesn't exist
        if term not in self.postings:
            self.postings[term] = dict()

        # Increase the frequency of the term in the document
        self.postings[term][doc_id] = self.postings[term].get(doc_id, 0) + frequency
        # Increase the overall frequency of the term in the posting list
        self.term_frequencies[term] = self.term_frequencies.get(term, 0) + frequency
        # Increase the number of documents in which the term appears
        self.document_frequencies[term] = self.document_frequencies.get(term, 0) + 1
        # Increase the number of unique terms in the document
        self.document_lengths[doc_id] = self.document_lengths.get(doc_id, 0) + 1

    def get_term_frequency(self, term: str) -> int:
        return self.term_frequencies.get(term, 0)

    def get_document_frequency(self, term: str) -> int:
        return self.document_frequencies.get(term, 0)

    def get_document_length(self, doc_id: int) -> int:
        return self.document_lengths.get(doc_id, 0)

    def get_all_term_frequencies(self) -> dict[str, int]:
        return dict(self.term_frequencies)

    def get_all_document_frequencies(self) -> dict[str, int]:
        return dict(self.document_frequencies)

    def get_all_document_lengths(self) -> dict[int, int]:
        return dict(self.document_lengths)

    def get_postings(self, term: str) -> dict[int, int]:
        return dict(self.postings.get(term, dict()))

    def get_vocabulary(self) -> set[str]:
        return set(self.postings.keys())

    def add_documents(self, documents: dict[int, str]):
        """
        Adds multiple documents to the posting list. Do not call this method more than once for the same document collection, as it will result in incorrect term frequencies and document frequencies.
        """
        for doc_id, document in documents.items():
            index_terms = get_index_terms_freq(document, self.pipeline_options)
            for term, frequency in index_terms.items():
                self._add_posting(term, frequency, doc_id)