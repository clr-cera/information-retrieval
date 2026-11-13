from __future__ import annotations

import random
import string
from collections import Counter
from collections.abc import Iterable, Mapping
from dataclasses import dataclass

from document_processor import normalize, tokenize

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
