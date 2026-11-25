"""Testes de ir.lexical."""

from __future__ import annotations

# ============================================================================
# Origem: src/document_processor_test.py
# ============================================================================

import pytest

import ir.lexical as document_processor

SAMPLE_DOCUMENT = "This is a sample document. It contains several words!"

def test_tokenize():
    document = "This is a sample document. It contains several words!"
    expected_tokens = ["This", "is", "a", "sample", "document", "It", "contains", "several", "words"]
    assert document_processor.tokenize(document) == expected_tokens

def test_normalize():
    term = ["HELLO"]
    expected_normalized_term = ["hello"]
    assert document_processor.normalize(term) == expected_normalized_term

def test_remove_stopwords():
    tokens = ["this", "is", "a", "sample", "document"]
    expected_filtered_tokens = ["sample", "document"]
    assert document_processor.remove_stopwords(tokens) == expected_filtered_tokens

def test_lemmatize():
    tokens = ["running", "jumps", "easily", "fairly", "better"]
    expected_lemmatized_tokens = ["run", "jump", "easily", "fairly", "well"]
    assert document_processor.lemmatize(tokens) == expected_lemmatized_tokens

def test_stem():
    tokens = ["running", "jumps", "easily", "fairly", "better"]
    expected_stemmed_tokens = ["run", "jump", "easili", "fairli", "better"]
    assert document_processor.stem(tokens) == expected_stemmed_tokens

def test_get_index_terms_freq_with_stopwords_and_stemming():
    expected_index_terms = {"sampl": 1, "document": 1, "contain": 1, "sever": 1, "word": 1}
    assert document_processor.get_index_terms_freq(SAMPLE_DOCUMENT, document_processor.PipelineOptions.WithStopRemovalWithStemming) == expected_index_terms

def test_get_index_terms_freq_without_stopwords_and_stemming():
    expected_index_terms = {"this": 1, "is": 1, "a": 1, "sample": 1, "document": 1, "it": 1, "contains": 1, "several": 1, "words": 1}
    assert document_processor.get_index_terms_freq(SAMPLE_DOCUMENT, document_processor.PipelineOptions.NoStopRemovalNoStemming) == expected_index_terms

def test_get_index_terms_freq_with_stopwords_without_stemming():
    expected_index_terms = {"sample": 1, "document": 1, "contains": 1, "several": 1, "words": 1}
    assert document_processor.get_index_terms_freq(SAMPLE_DOCUMENT, document_processor.PipelineOptions.WithStopRemovalNoStemming) == expected_index_terms

def test_get_index_terms_freq_without_stopwords_with_stemming():
    expected_index_terms = {"thi": 1, "is": 1, "a": 1, "sampl": 1, "document": 1, "it": 1, "contain": 1, "sever": 1, "word": 1}
    assert document_processor.get_index_terms_freq(SAMPLE_DOCUMENT, document_processor.PipelineOptions.NoStopRemovalWithStemming) == expected_index_terms

def test_pipeline_options_str():
    assert str(document_processor.PipelineOptions.WithStopRemovalWithStemming) == "WithStopRemovalWithStemming"

def test_pipeline_options_repr():
    assert repr(document_processor.PipelineOptions.WithStopRemovalWithStemming) == "WithStopRemovalWithStemming"

def test_pipeline_options_eq():
    assert document_processor.PipelineOptions.NoStopRemovalNoStemming == document_processor.PipelineOptions.NoStopRemovalNoStemming
    assert document_processor.PipelineOptions.NoStopRemovalNoStemming != document_processor.PipelineOptions.WithStopRemovalWithStemming
    assert (document_processor.PipelineOptions.NoStopRemovalNoStemming == "NoStopRemovalNoStemming") is False

def test_pipeline_options_invalid():
    invalid_option = object.__new__(document_processor.PipelineOptions)
    invalid_option._name_ = "InvalidOption"
    invalid_option._value_ = 99
    with pytest.raises(ValueError, match="Invalid PipelineOption"):
        invalid_option._to_pipeline()

def test_everything():
    print("testing tokenize()...")
    test_tokenize()
    print("testing normalize()...")
    test_normalize()
    print("testing remove_stopwords()...")
    test_remove_stopwords()
    print("testing lemmatize()...")
    test_lemmatize()
    print("testing stem()...")
    test_stem()
    print("testing get_index_terms_freq_with_stopwords_and_stemming()...")
    test_get_index_terms_freq_with_stopwords_and_stemming()
    print("testing get_index_terms_freq_without_stopwords_and_stemming()...")
    test_get_index_terms_freq_without_stopwords_and_stemming()
    print("testing get_index_terms_freq_with_stopwords_without_stemming()...")
    test_get_index_terms_freq_with_stopwords_without_stemming()
    print("testing get_index_terms_freq_without_stopwords_with_stemming()...")
    test_get_index_terms_freq_without_stopwords_with_stemming()
    print("testing pipeline_options_str()...")
    test_pipeline_options_str()
    print("testing pipeline_options_repr()...")
    test_pipeline_options_repr()
    print("testing pipeline_options_eq()...")
    test_pipeline_options_eq()
    print("testing pipeline_options_invalid()...")
    test_pipeline_options_invalid()


# ============================================================================
# Origem: src/posting_list_test.py
# ============================================================================

from ir.lexical import PostingList
DOCUMENTS = {
    1: "This is the first document.",
    2: "This document is the second document.",
    3: "And this is the third one.",
    4: "Is this the first document?",
}


def test_posting_list_postings():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Test get_postings
    assert posting_list.get_postings("first") == {1: 1, 4: 1}
    assert posting_list.get_postings("document") == {1: 1, 2: 2, 4: 1}
    assert posting_list.get_postings("second") == {2: 1}
    assert posting_list.get_postings("third") == {3: 1}
    assert posting_list.get_postings("nonexistent") == {}

def test_posting_list_term_frequencies():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Test get_term_frequency
    assert posting_list.get_term_frequency("first") == 2
    assert posting_list.get_term_frequency("document") == 4
    assert posting_list.get_term_frequency("second") == 1
    assert posting_list.get_term_frequency("third") == 1
    assert posting_list.get_term_frequency("nonexistent") == 0

def test_posting_list_term_doc_frequencies():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Test get_document_frequency
    assert posting_list.get_document_frequency("first") == 2
    assert posting_list.get_document_frequency("document") == 3
    assert posting_list.get_document_frequency("second") == 1
    assert posting_list.get_document_frequency("third") == 1
    assert posting_list.get_document_frequency("nonexistent") == 0

def test_posting_list_vocabulary():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Test get_vocabulary
    expected_vocabulary = {"first", "document", "second", "third", "one"}
    assert posting_list.get_vocabulary() == expected_vocabulary

def test_posting_list_add_collection():
    posting_list = PostingList()
    collection = {1: "This is the first document."}
    posting_list.add_documents(collection)

    # Test get_postings
    assert posting_list.get_postings("first") == {1: 1}
    assert posting_list.get_postings("document") == {1: 1}

def test_posting_list_getters_return_copies():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    postings = posting_list.get_postings("first")
    postings[1] = 999
    assert posting_list.get_postings("first") == {1: 1, 4: 1}

    term_frequencies = posting_list.get_all_term_frequencies()
    term_frequencies["first"] = 999
    assert posting_list.get_term_frequency("first") == 2

def test_posting_list_get_all_frequencies():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Test get_all_term_frequencies
    expected_frequencies = {
        "first": 2,
        "document": 4,
        "second": 1,
        "third": 1,
        "one": 1,
    }
    assert posting_list.get_all_term_frequencies() == expected_frequencies

def test_posting_list_get_all_term_doc_frequencies():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Test get_all_document_frequencies
    expected_frequencies = {
        "first": 2,
        "document": 3,
        "second": 1,
        "third": 1,
        "one": 1,
    }
    assert posting_list.get_all_document_frequencies() == expected_frequencies

def test_posting_list_doc_frequencies():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Test get_document_length
    assert posting_list.get_document_length(1) == 2
    assert posting_list.get_document_length(2) == 3
    assert posting_list.get_document_length(3) == 2
    assert posting_list.get_document_length(4) == 2
    assert posting_list.get_document_length(5) == 0

    # Test get_all_document_lengths
    assert posting_list.get_all_document_lengths() == {1: 2, 2: 3, 3: 2, 4: 2}

def test_posting_list_global_statistics():
    posting_list = PostingList()
    posting_list.add_documents(DOCUMENTS)

    # Global statistics are maintained during indexing (used by BM25 at query time)
    assert posting_list.total_length == 9
    assert posting_list.get_document_count() == 4
    assert posting_list.get_average_document_length() == 9 / 4


def test_posting_list_average_length_of_empty_index():
    assert PostingList().get_average_document_length() == 0.0


# ============================================================================
# Origem: src/lexical_index_test.py
# ============================================================================

import math

import pytest

from ir.lexical import PipelineOptions
from ir.lexical import LexicalIndex
from ir.lexical import evaluate_bm25

INDEX_DOCUMENTS = {
    "d1": "retrieval information retrieval",
    "d2": "information systems",
    "d3": "database systems",
}


def test_index_statistics():
    index = LexicalIndex(INDEX_DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    stats = index.stats

    assert stats.document_count == 3
    assert stats.vocabulary_size == 4
    assert stats.posting_count == 6
    assert stats.average_document_length == pytest.approx(7 / 3)
    assert stats.build_time_seconds >= 0.0


def test_bm25_returns_only_documents_with_query_terms():
    index = LexicalIndex(INDEX_DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    model = index.build_bm25(1.2, 0.75)

    ranking = model.execute_query("retrieval", return_scores=True)

    assert [doc_id for doc_id, _ in ranking] == ["d1"]
    assert model.execute_query("nonexistent") == []


def test_evaluate_bm25_produces_metrics_and_timings():
    index = LexicalIndex(INDEX_DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    queries = {"q1": "information retrieval"}
    qrels = {"q1": {"d1": 1, "d2": 0}}

    run = evaluate_bm25(index, queries, qrels, 1.2, 0.75)

    assert run.rankings["q1"][0][0] == "d1"
    assert run.metrics_by_query["q1"] == {
        "P10": 0.1,
        "R10": 1.0,
        "AP10": 1.0,
        "NDCG10": 1.0,
    }
    assert run.aggregated_metrics == run.metrics_by_query["q1"]
    assert run.average_query_time_seconds >= 0.0


def test_bm25_score_matches_formula():
    index = LexicalIndex(INDEX_DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    k1, b = 1.2, 0.75
    model = index.build_bm25(k1, b)

    ranking = dict(model.execute_query("retrieval", return_scores=True))

    # "retrieval": df = 1 of N = 3 documents; d1 has tf = 2 and length 3; avgdl = 7 / 3
    idf = math.log(1 + (3 - 1 + 0.5) / (1 + 0.5))
    expected = idf * 2 * (k1 + 1) / (2 + k1 * (1 - b + b * 3 / (7 / 3)))
    assert ranking["d1"] == pytest.approx(expected)


def test_bm25_query_does_not_copy_collection_statistics(monkeypatch):
    index = LexicalIndex(INDEX_DOCUMENTS, PipelineOptions.NoStopRemovalNoStemming)
    model = index.build_bm25(1.2, 0.75)

    def fail(*_args, **_kwargs):
        raise AssertionError("BM25 must not copy or scan collection-wide statistics per query")

    monkeypatch.setattr(index.posting_list, "get_all_document_lengths", fail)
    monkeypatch.setattr(index.posting_list, "get_all_document_frequencies", fail)

    ranking = model.execute_query("information", return_scores=True)
    assert {doc_id for doc_id, _ in ranking} == {"d1", "d2"}


# ============================================================================
# Origem: src/typo_correction_test.py
# ============================================================================

import random
from collections import Counter

import pytest

from ir.lexical import ERROR_TYPES, SpellingCorrector, build_dictionary, generate_error_variants, inject_error, inject_query_error, jaccard_similarity, k_grams, levenshtein_distance

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
