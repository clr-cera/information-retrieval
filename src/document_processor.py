def get_index_terms(document: str) -> dict[str, int]:
    """
    Extracts index terms from the document.

    Returns:
        term_frequencies (dict): A dictionary where keys are index terms and values are their corresponding frequencies in the document.
    """
    # Implementation for extracting index terms goes here
    tokens = tokenize(document)
    _normalized_tokens = [normalize(token) for token in tokens]
    return {}

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

def normalize(term: str) -> str:
    """
    Normalizes a term by converting it to lowercase.

    Returns:
        normalized_term (str): The normalized term.
    """
    return term.lower()