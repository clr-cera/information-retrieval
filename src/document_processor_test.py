import document_processor

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