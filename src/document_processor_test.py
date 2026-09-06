import pytest

import document_processor

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