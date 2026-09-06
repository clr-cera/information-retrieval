from enum import Enum
from collections import Counter

import nltk
from nltk.corpus import wordnet
nltk.download("stopwords")
nltk.download('wordnet')
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
nltk.download('averaged_perceptron_tagger_eng')

class PipelineOptions(Enum):
    NoStopRemovalNoStemming = 1
    NoStopRemovalWithStemming = 2
    WithStopRemovalNoStemming = 3
    WithStopRemovalWithStemming = 4

    def __str__(self):
        return self.name
    def __repr__(self):
        return self.name
    def __eq__(self, other):
        if isinstance(other, PipelineOptions):
            return self.value == other.value
        return NotImplemented
    def _to_pipeline(self):
        if self == PipelineOptions.NoStopRemovalNoStemming:
            return [tokenize, normalize]
        elif self == PipelineOptions.NoStopRemovalWithStemming:
            return [tokenize, normalize, stem]
        elif self == PipelineOptions.WithStopRemovalNoStemming:
            return [tokenize, normalize, remove_stopwords]
        elif self == PipelineOptions.WithStopRemovalWithStemming:
            return [tokenize, normalize, remove_stopwords, stem]
        else:
            raise ValueError(f"Invalid PipelineOption: {self}")


def get_index_terms_freq(document: str, options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming) -> dict[str, int]:
    """
    Extracts index terms from the document.

    Args:
        document (str): The input document.
        options (PipelineOptions): The pipeline options to use.

    Returns:
        term_frequencies (dict): A dictionary where keys are index terms and values are their corresponding frequencies in the document.
    """

    pipeline = options._to_pipeline()
    mid_result = document
    for step in pipeline:
        mid_result = step(mid_result)
    return dict(Counter(mid_result))

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

def lemmatize(tokens: list[str]) -> list[str]:
    """
    Lemmatizes the list of tokens.

    Returns:
        lemmatized_tokens (list): A list of lemmatized tokens.
    """
    lemmatizer = nltk.stem.WordNetLemmatizer()
    return list(map(lambda token: lemmatizer.lemmatize(token, get_wordnet_pos(token)), tokens))

def get_wordnet_pos(word):
    tag = nltk.pos_tag([word])[0][1][0].upper()
    tag_dict = {"J": wordnet.ADJ,
                "N": wordnet.NOUN,
                "V": wordnet.VERB,
                "R": wordnet.ADV}
    return tag_dict.get(tag, wordnet.NOUN)

def stem(tokens: list[str]) -> list[str]:
    """
    Stems the list of tokens.

    Returns:
        stemmed_tokens (list): A list of stemmed tokens.
    """
    stemmer = nltk.stem.PorterStemmer()
    return list(map(stemmer.stem, tokens))