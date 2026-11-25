"""Sistema lexical: pré-processamento, índice invertido, BM25, execução/avaliação e correção ortográfica."""

from __future__ import annotations

# ============================================================================
# Origem: src/document_processor.py
# ============================================================================

from enum import Enum
from collections import Counter

import nltk
from nltk.corpus import wordnet
nltk.download("stopwords")
nltk.download('wordnet')
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
nltk.download('averaged_perceptron_tagger_eng')

class PipelineOptions(Enum):
    NoStopRemovalNoStemming = 1
    NoStopRemovalWithStemming = 2
    WithStopRemovalNoStemming = 3
    WithStopRemovalWithStemming = 4

    def __str__(self):
        return self.name
    def __repr__(self):
        return self.name
    def __eq__(self, other):
        if isinstance(other, PipelineOptions):
            return self.value == other.value
        return NotImplemented
    def _to_pipeline(self):
        if self == PipelineOptions.NoStopRemovalNoStemming:
            return [tokenize, normalize]
        elif self == PipelineOptions.NoStopRemovalWithStemming:
            return [tokenize, normalize, stem]
        elif self == PipelineOptions.WithStopRemovalNoStemming:
            return [tokenize, normalize, remove_stopwords]
        elif self == PipelineOptions.WithStopRemovalWithStemming:
            return [tokenize, normalize, remove_stopwords, stem]
        else:
            raise ValueError(f"Invalid PipelineOption: {self}")


def get_index_terms_freq(document: str, options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming) -> dict[str, int]:
    """
    Extracts index terms from the document.

    Args:
        document (str): The input document.
        options (PipelineOptions): The pipeline options to use.

    Returns:
        term_frequencies (dict): A dictionary where keys are index terms and values are their corresponding frequencies in the document.
    """

    pipeline = options._to_pipeline()
    mid_result = document
    for step in pipeline:
        mid_result = step(mid_result)
    return dict(Counter(mid_result))

def tokenize(document: str) -> list[str]:
    """
    Tokenizes the document into individual terms.

    Returns:
        tokens (list): A list of tokens extracted from the document.
    """
    return list(map(
        lambda word: "".join(c for c in word if c.isalnum()),
        document.strip().split()
        ))

def normalize(tokens: list[str]) -> list[str]:
    """
    Normalizes a term by converting it to lowercase.

    Returns:
        normalized_tokens (list): A list of normalized tokens.
    """
    return list(map(str.lower, tokens))

def remove_stopwords(tokens: list[str]) -> list[str]:
    """
    Removes stopwords from the list of tokens.

    Returns:
        filtered_tokens (list): A list of tokens with stopwords removed.
    """
    stopwords = set(nltk.corpus.stopwords.words("english"))
    return list(filter(lambda token: token not in stopwords, tokens))

def lemmatize(tokens: list[str]) -> list[str]:
    """
    Lemmatizes the list of tokens.

    Returns:
        lemmatized_tokens (list): A list of lemmatized tokens.
    """
    lemmatizer = nltk.stem.WordNetLemmatizer()
    return list(map(lambda token: lemmatizer.lemmatize(token, get_wordnet_pos(token)), tokens))

def get_wordnet_pos(word):
    tag = nltk.pos_tag([word])[0][1][0].upper()
    tag_dict = {"J": wordnet.ADJ,
                "N": wordnet.NOUN,
                "V": wordnet.VERB,
                "R": wordnet.ADV}
    return tag_dict.get(tag, wordnet.NOUN)

def stem(tokens: list[str]) -> list[str]:
    """
    Stems the list of tokens.

    Returns:
        stemmed_tokens (list): A list of stemmed tokens.
    """
    stemmer = nltk.stem.PorterStemmer()
    return list(map(stemmer.stem, tokens))


# ============================================================================
# Origem: src/posting_list.py
# ============================================================================

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
        # The document_lengths dictionary maps document IDs to the number of total terms in the document.
        self.document_lengths: dict[int, int] = {}
        # Sum of all document lengths, kept up to date so avgdl is O(1) at query time.
        self.total_length: int = 0

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
        self.document_lengths[doc_id] = self.document_lengths.get(doc_id, 0) + frequency
        self.total_length += frequency

    def get_document_term_frequency(self, term: str, doc_id) -> int:
        return self.postings.get(term, 0).get(doc_id, 0)

    def get_term_frequency(self, term: str) -> int:
        return self.term_frequencies.get(term, 0)

    def get_document_frequency(self, term: str) -> int:
        return self.document_frequencies.get(term, 0)

    def get_document_length(self, doc_id: int) -> int:
        return self.document_lengths.get(doc_id, 0)

    def get_document_count(self) -> int:
        return len(self.document_lengths)

    def get_average_document_length(self) -> float:
        document_count = len(self.document_lengths)
        return self.total_length / document_count if document_count else 0.0

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


# ============================================================================
# Origem: src/probabilistic_model.py
# ============================================================================

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


# ============================================================================
# Origem: src/lexical_index.py
# ============================================================================

from collections.abc import Mapping
from dataclasses import dataclass
from time import perf_counter



@dataclass(frozen=True)
class IndexStats:
    document_count: int
    vocabulary_size: int
    posting_count: int
    build_time_seconds: float
    average_document_length: float

    def as_dict(self) -> dict[str, float | int]:
        return {
            "document_count": self.document_count,
            "vocabulary_size": self.vocabulary_size,
            "posting_count": self.posting_count,
            "build_time_seconds": self.build_time_seconds,
            "average_document_length": self.average_document_length,
        }


class LexicalIndex:
    def __init__(
        self,
        documents: Mapping[str, str],
        pipeline_options: PipelineOptions,
    ):
        self.pipeline_options = pipeline_options
        start = perf_counter()
        self.posting_list = PostingList(pipeline_options)
        self.posting_list.add_documents(dict(documents))
        self.build_time_seconds = perf_counter() - start

    @property
    def stats(self) -> IndexStats:
        document_lengths = self.posting_list.document_lengths
        document_count = len(document_lengths)
        average_document_length = (
            sum(document_lengths.values()) / document_count if document_count else 0.0
        )
        return IndexStats(
            document_count=document_count,
            vocabulary_size=len(self.posting_list.postings),
            posting_count=sum(
                len(postings) for postings in self.posting_list.postings.values()
            ),
            build_time_seconds=self.build_time_seconds,
            average_document_length=average_document_length,
        )

    def build_bm25(self, k1: float, b: float) -> ProbabilisticModel:
        return ProbabilisticModel(
            self.posting_list,
            self.pipeline_options,
            k=k1,
            b=b,
        )


# ============================================================================
# Origem: src/lexical_retrieval.py
# ============================================================================

from collections.abc import Mapping
from dataclasses import dataclass
from time import perf_counter

from ir.metrics import aggregate_metrics, compute_per_query_metrics


@dataclass(frozen=True)
class LexicalRun:
    rankings: dict[str, list[tuple[str, float]]]
    metrics_by_query: dict[str, dict[str, float]]
    query_times: dict[str, float]
    aggregated_metrics: dict[str, float]
    index_stats: IndexStats

    @property
    def average_query_time_seconds(self) -> float:
        if not self.query_times:
            return 0.0
        return sum(self.query_times.values()) / len(self.query_times)


def evaluate_bm25(
    index: LexicalIndex,
    queries: Mapping[str, str],
    qrels_by_query: Mapping[str, Mapping[str, int]],
    k1: float,
    b: float,
) -> LexicalRun:
    model = index.build_bm25(k1, b)
    rankings: dict[str, list[tuple[str, float]]] = {}
    query_times: dict[str, float] = {}

    for query_id, query_text in queries.items():
        start = perf_counter()
        rankings[query_id] = model.execute_query(query_text, return_scores=True)
        query_times[query_id] = perf_counter() - start

    ranked_doc_ids = {
        query_id: [str(doc_id) for doc_id, _ in ranking]
        for query_id, ranking in rankings.items()
    }
    metrics_by_query = compute_per_query_metrics(ranked_doc_ids, qrels_by_query)

    return LexicalRun(
        rankings=rankings,
        metrics_by_query=metrics_by_query,
        query_times=query_times,
        aggregated_metrics=aggregate_metrics(metrics_by_query),
        index_stats=index.stats,
    )


# ============================================================================
# Origem: src/typo_correction.py
# ============================================================================

import random
import string
from collections import Counter
from collections.abc import Iterable, Mapping
from dataclasses import dataclass


ERROR_TYPES = ("insercao", "remocao", "substituicao", "transposicao")


@dataclass(frozen=True)
class CorrectionCandidate:
    term: str
    edit_distance: int
    jaccard: float
    frequency: int


@dataclass(frozen=True)
class InjectedError:
    query: str
    original_token: str
    erroneous_token: str
    error_type: str


def tokenize_for_correction(text: str) -> list[str]:
    return normalize(tokenize(text))


def build_dictionary(documents: Mapping[str, str]) -> Counter[str]:
    frequencies: Counter[str] = Counter()
    for document in documents.values():
        frequencies.update(tokenize_for_correction(document))
    return frequencies


def k_grams(term: str, k: int) -> frozenset[str]:
    if k <= 0:
        raise ValueError("k must be positive")
    padded = f"^{term}$"
    if len(padded) <= k:
        return frozenset({padded})
    return frozenset(padded[index : index + k] for index in range(len(padded) - k + 1))


def jaccard_similarity(first: Iterable[str], second: Iterable[str]) -> float:
    first_set = set(first)
    second_set = set(second)
    union = first_set | second_set
    if not union:
        return 0.0
    return len(first_set & second_set) / len(union)


def levenshtein_distance(first: str, second: str) -> int:
    if first == second:
        return 0
    if len(first) < len(second):
        first, second = second, first

    previous = list(range(len(second) + 1))
    for first_index, first_char in enumerate(first, start=1):
        current = [first_index]
        for second_index, second_char in enumerate(second, start=1):
            insertion = current[second_index - 1] + 1
            deletion = previous[second_index] + 1
            substitution = previous[second_index - 1] + (first_char != second_char)
            current.append(min(insertion, deletion, substitution))
        previous = current
    return previous[-1]


class SpellingCorrector:
    def __init__(
        self,
        vocabulary: Mapping[str, int] | Iterable[str],
        kgram_size: int = 3,
        jaccard_threshold: float = 0.3,
        max_edit_distance: int = 2,
        max_candidates: int = 10,
    ):
        if isinstance(vocabulary, Mapping):
            self.frequencies = dict(vocabulary)
        else:
            self.frequencies = {term: 1 for term in vocabulary}

        if not 0.0 <= jaccard_threshold <= 1.0:
            raise ValueError("jaccard_threshold must be between 0 and 1")
        if max_edit_distance < 0:
            raise ValueError("max_edit_distance must be non-negative")

        self.vocabulary = set(self.frequencies)
        self.kgram_size = kgram_size
        self.jaccard_threshold = jaccard_threshold
        self.max_edit_distance = max_edit_distance
        self.max_candidates = max_candidates
        self.term_grams = {
            term: k_grams(term, kgram_size) for term in self.vocabulary
        }
        self.kgram_index: dict[str, set[str]] = {}
        for term, grams in self.term_grams.items():
            for gram in grams:
                self.kgram_index.setdefault(gram, set()).add(term)

    def candidates(self, token: str) -> list[CorrectionCandidate]:
        if token in self.vocabulary:
            return [
                CorrectionCandidate(
                    term=token,
                    edit_distance=0,
                    jaccard=1.0,
                    frequency=self.frequencies.get(token, 0),
                )
            ]

        token_grams = k_grams(token, self.kgram_size)
        candidate_terms: set[str] = set()
        for gram in token_grams:
            candidate_terms.update(self.kgram_index.get(gram, set()))

        candidates: list[CorrectionCandidate] = []
        for candidate in candidate_terms:
            similarity = jaccard_similarity(token_grams, self.term_grams[candidate])
            if similarity < self.jaccard_threshold:
                continue
            distance = levenshtein_distance(token, candidate)
            if distance > self.max_edit_distance:
                continue
            candidates.append(
                CorrectionCandidate(
                    term=candidate,
                    edit_distance=distance,
                    jaccard=similarity,
                    frequency=self.frequencies.get(candidate, 0),
                )
            )

        candidates.sort(
            key=lambda candidate: (
                candidate.edit_distance,
                -candidate.jaccard,
                -candidate.frequency,
                candidate.term,
            )
        )
        if self.max_candidates > 0:
            return candidates[: self.max_candidates]
        return candidates

    def correct_token(self, token: str) -> str:
        if token in self.vocabulary:
            return token
        candidates = self.candidates(token)
        return candidates[0].term if candidates else token

    def correct_tokens(self, tokens: Iterable[str]) -> list[str]:
        return [self.correct_token(token) for token in tokens]

    def correct_query(self, query: str) -> str:
        return " ".join(self.correct_tokens(tokenize_for_correction(query)))


def generate_error_variants(term: str, error_type: str) -> list[str]:
    variants: list[str] = []
    if error_type == "insercao":
        for index in range(len(term) + 1):
            for letter in string.ascii_lowercase:
                variants.append(term[:index] + letter + term[index:])
    elif error_type == "remocao":
        if len(term) > 1:
            for index in range(len(term)):
                variants.append(term[:index] + term[index + 1 :])
    elif error_type == "substituicao":
        for index, char in enumerate(term):
            for letter in string.ascii_lowercase:
                if letter != char:
                    variants.append(term[:index] + letter + term[index + 1 :])
    elif error_type == "transposicao":
        for index in range(len(term) - 1):
            if term[index] != term[index + 1]:
                variants.append(
                    term[:index]
                    + term[index + 1]
                    + term[index]
                    + term[index + 2 :]
                )
    else:
        raise ValueError(f"Invalid error type {error_type!r}. Expected one of {ERROR_TYPES}.")

    unique_variants: list[str] = []
    seen: set[str] = set()
    for variant in variants:
        if variant and variant not in seen:
            seen.add(variant)
            unique_variants.append(variant)
    return unique_variants


def inject_error(
    term: str,
    error_type: str,
    vocabulary: Iterable[str] | Mapping[str, int],
    rng: random.Random | None = None,
) -> str | None:
    vocabulary_set = _vocabulary_set(vocabulary)
    variants = [
        variant
        for variant in generate_error_variants(term, error_type)
        if variant not in vocabulary_set
    ]
    if not variants:
        return None
    if rng is not None:
        return rng.choice(variants)
    return variants[0]


def inject_query_error(
    query: str,
    error_type: str,
    vocabulary: Iterable[str] | Mapping[str, int],
    rng: random.Random | None = None,
    excluded_tokens: Iterable[str] = (),
    min_token_length: int = 4,
) -> InjectedError | None:
    vocabulary_set = _vocabulary_set(vocabulary)
    excluded = set(excluded_tokens)
    tokens = tokenize_for_correction(query)
    candidate_indices = sorted(
        (
            index
            for index, token in enumerate(tokens)
            if len(token) >= min_token_length
            and token.isalpha()
            and token in vocabulary_set
            and token not in excluded
        ),
        key=lambda index: (-len(tokens[index]), index),
    )

    for index in candidate_indices:
        original_token = tokens[index]
        erroneous_token = inject_error(
            original_token,
            error_type,
            vocabulary_set,
            rng=rng,
        )
        if erroneous_token is None:
            continue
        corrupted_tokens = list(tokens)
        corrupted_tokens[index] = erroneous_token
        return InjectedError(
            query=" ".join(corrupted_tokens),
            original_token=original_token,
            erroneous_token=erroneous_token,
            error_type=error_type,
        )

    return None


def _vocabulary_set(
    vocabulary: Iterable[str] | Mapping[str, int],
) -> set[str]:
    if isinstance(vocabulary, set):
        return vocabulary
    return set(vocabulary)
