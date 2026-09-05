import document_processor

def test_tokenize():
    document = "This is a sample document. It contains several words!"
    expected_tokens = ["This", "is", "a", "sample", "document", "It", "contains", "several", "words"]
    assert document_processor.tokenize(document) == expected_tokens

def test_normalize():
    term = "HELLO"
    expected_normalized_term = "hello"
    assert document_processor.normalize(term) == expected_normalized_term
