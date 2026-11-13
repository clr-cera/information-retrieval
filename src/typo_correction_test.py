import random
from collections import Counter

import pytest

from typo_correction import (
    ERROR_TYPES,
    SpellingCorrector,
    build_dictionary,
    generate_error_variants,
    inject_error,
    inject_query_error,
    jaccard_similarity,
    k_grams,
    levenshtein_distance,
)

VOCABULARY = Counter(
    {
        "retrieval": 10,
        "information": 8,
        "system": 4,
        "systems": 3,
        "database": 2,
    }
)


def test_k_grams_include_boundaries():
    assert k_grams("cat", 3) == {"^ca", "cat", "at$"}


def test_jaccard_similarity():
    assert jaccard_similarity({"a", "b"}, {"a", "b"}) == 1.0
    assert jaccard_similarity({"a", "b"}, {"b", "c"}) == pytest.approx(1 / 3)
    assert jaccard_similarity(set(), set()) == 0.0


def test_levenshtein_distance():
    assert levenshtein_distance("kitten", "sitting") == 3
    assert levenshtein_distance("retrieval", "retreival") == 2
    assert levenshtein_distance("same", "same") == 0


def test_build_dictionary_uses_pre_stemming_terms():
    documents = {"d1": "Retrieval systems", "d2": "retrieval databases"}

    dictionary = build_dictionary(documents)

    assert dictionary["retrieval"] == 2
    assert dictionary["systems"] == 1
    assert dictionary["databases"] == 1
    assert "retriev" not in dictionary


def test_spelling_corrector_recovers_errors():
    corrector = SpellingCorrector(
        VOCABULARY,
        kgram_size=3,
        jaccard_threshold=0.3,
        max_edit_distance=2,
    )

    assert corrector.correct_token("retreival") == "retrieval"
    assert corrector.correct_token("informaton") == "information"
    assert corrector.correct_token("systems") == "systems"
    assert corrector.correct_query("retreival of informatton systems") == (
        "retrieval of information systems"
    )


def test_generate_error_variants_covers_all_types():
    for error_type in ERROR_TYPES:
        variants = generate_error_variants("retrieval", error_type)
        assert variants
        assert all(variant != "retrieval" for variant in variants)

    with pytest.raises(ValueError, match="Invalid error type"):
        generate_error_variants("retrieval", "unknown")


def test_inject_error_returns_oov_terms():
    vocabulary = set(VOCABULARY)
    for error_type in ERROR_TYPES:
        erroneous = inject_error("retrieval", error_type, vocabulary)
        assert erroneous is not None
        assert erroneous not in vocabulary


def test_inject_query_error_replaces_a_known_content_token():
    vocabulary = set(VOCABULARY)
    injected = inject_query_error(
        "information retrieval systems",
        "substituicao",
        vocabulary,
        rng=random.Random(42),
        excluded_tokens={"information"},
    )

    assert injected is not None
    assert injected.original_token in vocabulary
    assert injected.erroneous_token not in vocabulary
    assert injected.erroneous_token in injected.query
    assert injected.original_token not in injected.query
