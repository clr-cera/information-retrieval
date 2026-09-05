import nltk
nltk.download("stopwords")

def get_index_terms(document: str) -> dict[str, int]:
    """
    Extracts index terms from the document.

    Returns:
        term_frequencies (dict): A dictionary where keys are index terms and values are their corresponding frequencies in the document.
    """
    # Implementation for extracting index terms goes here
    tokens = tokenize(document)
    normalized_tokens = normalize(tokens)
    _filtered_tokens = remove_stopwords(normalized_tokens)
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