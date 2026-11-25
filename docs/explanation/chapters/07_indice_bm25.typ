#import "../estilo.typ": *

= Índice invertido e BM25 (`ir/lexical.py`, parte 2) <cap-bm25>

== Teoria do índice invertido

Para encontrar os documentos que contêm um termo sem ler a coleção inteira, guarda-se o mapeamento ao contrário: em vez de "documento → termos", "termo → documentos". Essa estrutura é o *índice invertido*.

- O *dicionário* (ou vocabulário) é o conjunto de termos.
- A *posting list* de um termo é a lista dos documentos em que ele aparece. Cada entrada (um *posting*) guarda o documento e a frequência do termo nele ($t f$).

Além disso, o modelo de ranqueamento precisa de estatísticas: quantos documentos contêm cada termo ($n_t$, a *document frequency*), o tamanho de cada documento ($|d|$), o número de documentos ($N$) e o tamanho médio ($"avgdl"$).

Uma consulta só precisa visitar as posting lists dos seus próprios termos. Uma consulta com 3 termos visita 3 listas, e não os 3.633 documentos: é isso que o enunciado exige ao proibir percorrer toda a coleção a cada consulta.

=== Exemplo

Três documentos, com o pipeline do sistema final:

#tabela(
  (auto, 1fr),
  [*Documento*], [*Texto → termos*],
  [d1], [vitamin D and bone health → `vitamin`, `bone`, `health`],
  [d2], [vitamin D vitamin D deficiency in older adults falls → `vitamin` (2×), `defici`, `older`, `adult`, `fall`],
  [d3], [exercise prevents falls → `exercis`, `prevent`, `fall`],
)

Estado do índice depois de inserir os três:

```python
postings = {
    "vitamin": {"d1": 1, "d2": 2},   "bone": {"d1": 1},   "health": {"d1": 1},
    "defici": {"d2": 1},  "older": {"d2": 1},  "adult": {"d2": 1},
    "fall": {"d2": 1, "d3": 1},  "exercis": {"d3": 1},  "prevent": {"d3": 1},
}
document_frequencies = {"vitamin": 2, "fall": 2, ... (os demais valem 1)}
document_lengths = {"d1": 3, "d2": 6, "d3": 3}
total_length = 12                     # avgdl = 12 / 3 = 4
```

== Teoria do BM25

O BM25 vem do modelo probabilístico de RI: ele estima o quanto é provável que um documento seja relevante a partir dos termos que ele compartilha com a consulta. O score é uma soma sobre os termos da consulta:

$ "score"(d, q) = sum_(t in q) "IDF"(t) dot (t f(t, d) dot (k_1 + 1)) / (t f(t, d) + k_1 dot (1 - b + b dot (|d|) / "avgdl")) $

$ "IDF"(t) = log(1 + (N - n_t + 0.5) / (n_t + 0.5)) $

Cada parte tem um papel:

- *IDF* (frequência inversa de documento): termos raros pesam mais. Um termo que está em quase todos os documentos não distingue nada; um termo presente em poucos é muito informativo. O "$1 +$" dentro do logaritmo garante IDF positivo mesmo quando o termo está em mais da metade da coleção.
- *Saturação ($k_1$)*: o peso cresce com $t f$, mas cada ocorrência a mais vale menos que a anterior; o termo nunca passa de $"IDF" dot (k_1+1)$. Com $k_1$ pequeno, satura rápido (aparecer 1 ou 10 vezes dá quase o mesmo); com $k_1$ grande, a frequência importa mais. O valor usual é 1,2.
- *Normalização pelo tamanho ($b$)*: documentos longos têm mais chance de conter os termos muitas vezes sem serem mais relevantes. O fator $1 - b + b dot |d|\/"avgdl"$ vale 1 para um documento de tamanho médio, mais que 1 para documentos longos (penaliza) e menos que 1 para curtos. Com $b = 0$, a normalização é desligada; com $b = 1$, é total. O valor usual é 0,75.

=== Exemplo calculado

Consulta "vitamin falls" → termos `vitamin` e `fall`, com $k_1 = "1,2"$ e $b = "0,75"$, no índice acima ($N = 3$, $"avgdl" = 4$).

- IDF: os dois termos estão em 2 documentos: $log(1 + (3 - 2 + "0,5")\/(2 + "0,5")) = log "1,6" = "0,4700"$.
- d2 ($|d| = 6$): o fator de tamanho é $"1,2" dot ("0,25" + "0,75" dot 6\/4) = "1,65"$.
  - `vitamin` ($t f = 2$): $"0,4700" dot (2 dot "2,2")\/(2 + "1,65") = "0,5666"$;
  - `fall` ($t f = 1$): $"0,4700" dot "2,2"\/(1 + "1,65") = "0,3902"$;
  - total: *0,9568*.
- d1 ($|d| = 3$, fator $"0,975"$), só `vitamin` com $t f = 1$: $"0,4700" dot "2,2"\/"1,975" =$ *0,5235*.
- d3: mesmo tamanho de d1 e só `fall` com $t f = 1$: também *0,5235*.

O ranking é d2, d1, d3. Os scores são exatamente os que o código devolve. d1 e d3 *empatam*: a ordem entre eles é decidida pela ordem em que foram encontrados (ver "Empates" abaixo).

== O código

Imports desta parte: `log` (de `math`), `Mapping`, `dataclass`, `perf_counter` e, de `ir.metrics`, `aggregate_metrics` e `compute_per_query_metrics`.

=== `PostingList`: o índice invertido

Atributos criados no construtor:

#tabela(
  (auto, auto, 1fr),
  [*Atributo*], [*Tipo*], [*Conteúdo*],
  [`postings`], [`dict[termo, dict[doc_id, tf]]`], [O índice: para cada termo, a posting list como dicionário.],
  [`term_frequencies`], [`dict[termo, int]`], [Total de ocorrências do termo na coleção (não é usado pelo BM25).],
  [`document_frequencies`], [`dict[termo, int]`], [$n_t$.],
  [`document_lengths`], [`dict[doc_id, int]`], [$|d|$: soma das frequências dos termos do documento.],
  [`total_length`], [`int`], [$sum |d|$, para obter o avgdl sem somar tudo de novo.],
  [`pipeline_options`], [`PipelineOptions`], [O pré-processamento usado na construção.],
)

As posting lists são dicionários, e não listas ordenadas. Dicionários dão acesso em tempo constante, e o BM25 só precisa percorrer cada lista uma vez; listas ordenadas por documento só seriam necessárias para intercalar listas, como em buscas booleanas.

#funcao("def add_documents(self, documents: dict) -> None")[
  Para cada documento, calcula os termos e frequências com `get_index_terms_freq` e insere cada par com `_add_posting`. Deve ser chamado uma vez só por coleção: chamar duas vezes contaria tudo em dobro.
]

#funcao("def _add_posting(self, term, frequency, doc_id) -> None")[
  Numa única operação: cria a posting list do termo se ela não existir; soma a frequência no posting do documento; soma na frequência total do termo; incrementa o $n_t$; soma no tamanho do documento e no `total_length`. Como `get_index_terms_freq` já agrupou as ocorrências, cada par (termo, documento) chega uma vez só, e o $n_t$ é incrementado uma vez por documento.
]

Métodos de consulta:

- `get_document_frequency(term)`, `get_document_length(doc_id)`, `get_term_frequency(term)`, `get_document_term_frequency(term, doc_id)`: leem um valor (0 se não existir).
- `get_document_count()`: $N$ = número de documentos, `len(document_lengths)`.
- `get_average_document_length()`: `total_length / N`, em tempo constante.
- `get_all_*()`, `get_postings(term)` e `get_vocabulary()`: devolvem *cópias* (`dict(...)`, `set(...)`), para quem chamar não alterar o índice por engano. Por copiarem tudo, *não* são usados na consulta.

=== `ProbabilisticModel`: o BM25

O construtor guarda uma *referência* à `PostingList` (não uma cópia), o pipeline e os parâmetros `k` ($k_1$) e `b`. `update_total_documents()` atualiza $N$.

#funcao("def execute_query(self, query, show_sim_score=False, return_scores=False)")[
  + Pré-processa a consulta com o *mesmo* pipeline dos documentos (`get_index_terms_freq`). Cada termo distinto conta uma vez: a frequência do termo dentro da consulta não é usada.
  + Obtém $N$ e o avgdl em tempo constante, e guarda referências diretas aos dicionários do índice (sem cópia).
  + Descarta os termos que não estão no vocabulário. Se `show_sim_score=True`, imprime quais foram ignorados (útil para depurar).
  + *Termo a termo, com acumuladores*: para cada termo, calcula o IDF uma vez e percorre só a sua posting list. Para cada documento da lista, calcula a contribuição do termo com o $t f$ do posting e o $|d|$ do documento, e soma em `docs_sim[doc_id]`. Documentos que não têm nenhum termo da consulta nunca são visitados.
  + Ordena por score decrescente.
  + Devolve só os identificadores ou, com `return_scores=True`, pares `(doc_id, score)`.

  O custo é proporcional à soma dos tamanhos das posting lists dos termos da consulta. No test, isso dá em média 558 postings por consulta, 0,16% dos 350.458 postings do índice.
]

#atencao(titulo: "Empates")[
  A ordenação usa `sorted(..., reverse=True)` só pelo score. Como a ordenação do Python é estável, documentos com o mesmo score ficam na ordem em que entraram em `docs_sim`, que é a ordem das posting lists (a ordem do `corpus.jsonl`). Isso é reprodutível, mas arbitrário. Com $b = 0$ os empates eram muito frequentes (93 das 324 consultas do dev tinham empate entre a 10ª e a 11ª posição), e a ordem de desempate podia mudar o NDCG\@10 do dev em até 0,017. Com $b = "0,75"$, o tamanho do documento quase sempre diferencia os scores (só 3 consultas com esse empate). Esse foi o motivo para adotar os valores usuais.
]

Uma consequência da busca restrita: o ranking lexical só contém documentos com algum termo da consulta. No test, 134 das 323 consultas recuperam menos de 100 documentos, e 16 não recuperam nenhum (todos os termos estão fora do vocabulário).

=== `LexicalIndex` e `IndexStats`

#funcao("class LexicalIndex(documents, pipeline_options)")[
  Constrói a `PostingList` e mede o tempo de construção com `perf_counter` (inclui o pré-processamento, que é quase todo o tempo: cerca de 5,5 s contra 0,27 s de inserção). A propriedade `stats` devolve um `IndexStats` com o número de documentos, o tamanho do vocabulário (`len(postings)`), o total de postings (soma dos tamanhos das listas), o tempo de construção e o tamanho médio. `build_bm25(k1, b)` cria um `ProbabilisticModel` sobre esse índice; o mesmo índice pode gerar modelos com parâmetros diferentes sem ser reconstruído (é assim que `tune_lexical.py` testa a grade).
]

Valores no test: 3.633 documentos, 28.942 termos, 350.458 postings, construção em cerca de 7 s e menos de 1 ms por consulta.

=== `evaluate_bm25` e `LexicalRun`

#funcao("def evaluate_bm25(index, queries, qrels_by_query, k1, b) -> LexicalRun")[
  Cria o modelo, executa cada consulta medindo o tempo, converte os rankings em listas de identificadores e calcula as métricas por consulta e as médias. Devolve um `LexicalRun` com: `rankings` (com scores), `metrics_by_query`, `query_times`, `aggregated_metrics` e `index_stats`. A propriedade `average_query_time_seconds` dá o tempo médio.
]

== Parâmetros escolhidos

A grade avaliada no dev foi $k_1 in {"0,5"; "1,2"; "2,0"}$ × $b in {0; "0,75"; "1,0"}$. Todo o intervalo ficou entre 0,2854 e 0,2916 de NDCG\@10: os parâmetros mudam pouco. O efeito pequeno de $b$ tem explicação nos dados: os documentos do NFCorpus têm tamanhos parecidos (80% entre 87 e 212 termos) e a relevância não depende do tamanho. O sistema usa $k_1 = "1,2"$ e $b = "0,75"$.
