#import "../estilo.typ": *

= Pré-processamento (`ir/lexical.py`, parte 1) <cap-preproc>

== Teoria

A busca lexical compara *termos*: um documento só é encontrado se tiver os mesmos termos da consulta. O pré-processamento transforma o texto em uma lista de termos de forma que variações sem importância não impeçam essa correspondência.

#tabela(
  (auto, 1fr, 1fr),
  [*Etapa*], [*O que faz*], [*Por quê*],
  [Tokenização], [Divide o texto em palavras (tokens).], [A unidade de comparação é a palavra, não o texto inteiro.],
  [Normalização], [Converte para minúsculas.], [`Vitamin` e `vitamin` devem ser o mesmo termo.],
  [Remoção de stopwords], [Remove palavras muito comuns e sem conteúdo (`the`, `of`, `in`, `and`).], [Elas aparecem em quase todos os documentos e não ajudam a distinguir um do outro; também aumentam o índice.],
  [Stemming], [Reduz a palavra a um radical por regras de corte de sufixos (`supplements` → `supplement`, `reduce` → `reduc`).], [Variações da mesma palavra (singular/plural, verbo/substantivo) passam a coincidir.],
  [Lematização (alternativa)], [Reduz a palavra à forma de dicionário (`studies` → `study`) usando um dicionário (WordNet) e a classe gramatical.], [Mais precisa que o stemming, mas mais lenta; não é usada no sistema final.],
)

O stemming de Porter aplica regras em etapas (por exemplo, `-ies` → `-i`, `-ing` → remove). O radical nem sempre é uma palavra real (`reduc`, `studi`), mas isso não importa: basta que variações da mesma palavra produzam o mesmo radical.

== Exemplo completo

Frase: "Vitamin D supplements reduce the risk of falls in older adults."

#tabela(
  (auto, 1fr),
  [*Etapa*], [*Resultado*],
  [Tokenização], [`Vitamin`, `D`, `supplements`, `reduce`, `the`, `risk`, `of`, `falls`, `in`, `older`, `adults` (o ponto final foi removido)],
  [Normalização], [`vitamin`, `d`, `supplements`, `reduce`, `the`, `risk`, `of`, `falls`, `in`, `older`, `adults`],
  [Stopwords], [`vitamin`, `supplements`, `reduce`, `risk`, `falls`, `older`, `adults` (saíram `the`, `of`, `in` e também `d`, que está na lista do NLTK)],
  [Stemming], [`vitamin`, `supplement`, `reduc`, `risk`, `fall`, `older`, `adult`],
  [Frequências], [`{vitamin: 1, supplement: 1, reduc: 1, risk: 1, fall: 1, older: 1, adult: 1}`],
)

Note que a letra "D" de "Vitamin D" foi descartada por coincidir com uma stopword do NLTK — um exemplo de como o pré-processamento pode perder informação.

== O código

=== Imports e downloads

- `Enum` (de `enum`): para `PipelineOptions`.
- `Counter` (de `collections`): para contar as frequências dos termos.
- `nltk`: a biblioteca de processamento de linguagem natural. Fornece a lista de stopwords, o stemmer de Porter, o lematizador WordNet e o etiquetador morfossintático.
- `wordnet` (de `nltk.corpus`): as constantes de classe gramatical usadas pelo lematizador (`wordnet.NOUN`, `wordnet.VERB` etc.).

Logo depois dos imports, o módulo chama `nltk.download(...)` para `stopwords`, `wordnet`, `punkt` e os etiquetadores (`averaged_perceptron_tagger` e a versão `_eng`). Esses recursos são dados, não código: na primeira execução são baixados para `~/nltk_data`; nas seguintes, o NLTK só confere que já existem (são as mensagens "already up-to-date" que aparecem ao rodar os scripts). O `punkt` (tokenizador de frases) é baixado, mas não é usado pelo código.

=== `PipelineOptions`

```python
class PipelineOptions(Enum):
    NoStopRemovalNoStemming = 1      # só tokenização e minúsculas
    NoStopRemovalWithStemming = 2    # + stemming
    WithStopRemovalNoStemming = 3    # + remoção de stopwords
    WithStopRemovalWithStemming = 4  # + remoção de stopwords + stemming (usada no sistema final)
```

As quatro combinações avaliadas no dev. Os métodos:

- `__str__` e `__repr__` devolvem o nome (é o que vai para os CSVs e para o config).
- `__eq__` compara pelo número.
- `_to_pipeline()` devolve a *lista de funções* a aplicar, em ordem. Por exemplo, a opção 4 devolve `[tokenize, normalize, remove_stopwords, stem]`. Funções em Python são objetos e podem ser guardadas numa lista.

=== Funções

#funcao("def get_index_terms_freq(document: str, options: PipelineOptions) -> dict[str, int]")[
  A função central do pré-processamento, usada tanto para documentos quanto para consultas. Obtém a lista de etapas com `options._to_pipeline()` e aplica uma após a outra: a saída de cada etapa é a entrada da próxima (`mid_result = step(mid_result)`). A primeira etapa recebe o texto e devolve uma lista de tokens; as demais recebem e devolvem listas. No fim, `Counter` conta as ocorrências e o resultado vira um dicionário `{termo: frequência}`.
]

#funcao("def tokenize(document: str) -> list[str]")[
  `document.strip().split()` divide o texto nos espaços em branco (espaço, tabulação, quebra de linha). Em cada pedaço, mantém só os caracteres alfanuméricos (`c.isalnum()`), removendo pontuação. Consequências:
  - pontuação *dentro* da palavra também some: `meta-analysis` vira `metaanalysis`, e `and/or` vira `andor`;
  - um pedaço formado só por pontuação (como um `-` isolado) vira o texto vazio `""`, que é mantido como token (ver a observação abaixo).
]

#funcao("def normalize(tokens: list[str]) -> list[str]")[Aplica `str.lower` a cada token.]

#funcao("def remove_stopwords(tokens: list[str]) -> list[str]")[
  Carrega a lista de stopwords em inglês do NLTK, transforma em conjunto (busca em tempo constante) e mantém os tokens que não estão nela. A lista é recarregada a cada chamada, o que custa tempo na construção do índice (uma chamada por documento).
]

#funcao("def stem(tokens: list[str]) -> list[str]")[Cria um `PorterStemmer` e aplica `stemmer.stem` a cada token.]

#funcao("def lemmatize(tokens: list[str]) -> list[str]  /  def get_wordnet_pos(word)")[
  Implementadas, mas não fazem parte de nenhuma opção do pipeline. `get_wordnet_pos` etiqueta a palavra isoladamente com `nltk.pos_tag` (sem o contexto da frase), pega a primeira letra da etiqueta (J = adjetivo, N = substantivo, V = verbo, R = advérbio) e a converte para a constante do WordNet; na dúvida, assume substantivo. `lemmatize` usa essa classe para chamar `WordNetLemmatizer.lemmatize`.
]

#atencao(titulo: "Token vazio no índice")[
  Como `tokenize` não descarta tokens vazios, a pontuação isolada vira o termo `""`. Ele aparece 6.109 vezes, em 1.513 documentos, e tem a 5ª maior posting list do índice. Não afeta consultas comuns, mas entra nas contagens do vocabulário. A correção seria descartar tokens vazios em `tokenize`; o grupo ainda não decidiu se fará isso.
]

== Escolha do pipeline

No dev, com os valores usuais do BM25, o NDCG\@10 foi: 0,2655 (nenhuma etapa extra), 0,2713 (só stopwords), 0,2876 (só stemming) e 0,2906 (stopwords + stemming). O stemming é a etapa que mais ajuda (+0,022); a remoção de stopwords quase não muda a qualidade, mas reduz o índice em cerca de 20% dos postings. O sistema final usa a opção 4.
