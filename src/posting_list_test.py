from posting_list import PostingList
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
    assert posting_list.get_document_length(2) == 2
    assert posting_list.get_document_length(3) == 2
    assert posting_list.get_document_length(4) == 2
    assert posting_list.get_document_length(5) == 0

    # Test get_all_document_lengths
    assert posting_list.get_all_document_lengths() == {1: 2, 2: 2, 3: 2, 4: 2}