# information-retrieval
Repo for ease of collaboration on information retrieval project

[X] Pre-Processing

[X] Vectorial Model

[X] Probabilistic Model (BM25)

[ ] Quantitative Valuation

[ ] Model comparing (between Vectorial Model and Probabilistic Model)

[ ] Analysis per query

[ ] BM25 parameters variaton

[ ] Query modification

[ ] Error analysis

# Document Processor Tools

```py
def get_index_terms_freq(document: str, options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming) -> dict[str, int]
```

Extracts index terms from the document.

Args - document (str): The input document | options (PipelineOptions): The pipeline options to use

Returns: term_frequencies (dict): A dictionary where keys are index terms and values are their corresponding frequencies in the document.

```
def tokenize(document: str) -> list[str]
```

Tokenizes the document into individual terms.

Returns: tokens (list): A list of tokens extracted from the document.

```py
normalize(tokens: list[str]) -> list[str]
```

Normalizes a term by converting it to lowercase.

Returns: normalized_tokens (list): A list of normalized tokens.

```py
remove_stopwords(tokens: list[str]) -> list[str]
```

Removes stopwords from the list of tokens.

Returns: filtered_tokens (list): A list of tokens with stopwords removed.

```py
lemmatize(tokens: list[str]) -> list[str]
```

Lemmatizes the list of tokens.

Returns: lemmatized_tokens (list): A list of lemmatized tokens.

```py
stem(tokens: list[str]) -> list[str]
```

Stems the list of tokens.

Returns: stemmed_tokens (list): A list of stemmed tokens.

## PipelineOptions Class

Defines pipeline for document processing. There are 4 options:

- `PipelineOptions.NoStopRemovalNoStemming`
- `PipelineOptions.NoStopRemovalWithStemming`
- `PipelineOptions.WithStopRemovalNoStemming`
- `PipelineOptions.WithStopRemovalWithStemming`

# Posting List Class

A class to represent a posting list (Inverted Index)

```py
new_posting_list = PostingList(PipelineOptions.WithStopRemovalWithStemming)
```

Class functions:

- `._add_posting(term: str, frequenc: int, doc_id: int)` - Adds a posting for a term in a specific document
- `.get_term_frequency(term: str) -> int` - Return overall frequency of a term in the posting list (tf)
- `.get_document_frequency(term:str) -> int` - Return number of documents in which the term appear (df)
- `.get_all_term_frequencies() -> dict[str,int]` - Return a dict of overall term frequencies (tf)
- `.get_all_document_frequencies() -> dict[str, int]` - Return a dict of terms and the number of documents in which each term appear (df)
- `.get_all_document_lengths() -> dict[int, int]` - Return a dict that maps document IDs to the number of total terms in the document
- `.get_postings(term: str) -> dict[int, int]` - Return the term posting list
- `.get_vocabulary() -> set[str]` - Return a set of overall unique terms
- `.add_documents(documents: dict[int, str])` - Adds multiple documents to the posting list. Do not call this method more than once for the same document collection, as it will result in incorrect term and document frequencies.

# Vectorial Model

Initializes a Vectorial Model instance. It requires a PostingList instance.

```py
model = VectorialModel(posting_list: PostingList, pipeline_options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming)
```

Class functions:

- `.execute_query(query: str, show_sim_score=False, return_scores=False) -> list[int] | list[tuple[int,float]]` - Get string as argument and return a sorted array (ranking) of document IDs.

# Probabilistic Model

Initializes a Probabilistic Model (BM25) instance. It requires a PostingList instance.

```py
model = ProbabilisticModel(posting_list: PostingList, pipeline_options: PipelineOptions = PipelineOptions.WithStopRemovalWithStemming, k: float = 1.2, b: float = 0.75)
```

Class functions

- `.execute_query(self, query: str, show_sim_score=False, return_scores=False) -> list[int] | list[tuple[int, float]]` - Get String as argument and return a sorted array (ranking) of document IDs.
