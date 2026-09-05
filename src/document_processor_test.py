import document_processor

def test_tokenize():
    document = "This is a sample document. It contains several words!"
    expected_tokens = ["This", "is", "a", "sample", "document", "It", "contains", "several", "words"]
    assert document_processor.tokenize(document) == expected_tokens
