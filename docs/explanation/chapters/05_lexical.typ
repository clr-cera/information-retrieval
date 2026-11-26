#import "../estilo.typ": *

= Busca lexical: pré-processamento, índice e BM25 (`ir/lexical.py`) <cap-lexical>

== Pré-processamento

A busca lexical compara *termos*: um documento só é encontrado se tiver termos da consulta. O pré-processamento transforma o texto em termos de forma que variações sem importância não atrapalhem essa correspondência. O *mesmo* pipeline é aplicado a documentos e consultas.

#tabela(
  (auto, 1fr),
  [*Etapa*], [*O que faz e por quê*],
  [Tokenização], [Divide nos espaços e remove os caracteres não alfanuméricos de cada pedaço.],
  [Normalização], [Minúsculas: `Vitamin` e `vitamin` viram o mesmo termo.],
  [Stopwords], [Remove palavras comuns sem conteúdo (lista do NLTK): não distinguem documentos e aumentam o índice.],
  [Stemming (Porter)], [Corta sufixos por regras (`supplements` → `supplement`, `reduce` → `reduc`): singular, plural e derivações passam a coincidir. O radical não precisa ser uma palavra real.],
)

Exemplo, com o pipeline final: "Vitamin D supplements reduce the risk of falls in older adults." → `vitamin, supplement, reduc, risk, fall, older, adult`. O "D" sumiu porque `d` está na lista de stopwords do NLTK — um exemplo de como o pré-processamento pode perder informação.

O enum `PipelineOptions` define as quatro combinações avaliadas no dev (com e sem stopwords × com e sem stemming), e `get_index_terms_freq` aplica as etapas em sequência e devolve `{termo: frequência}`. A lematização (WordNet) está implementada, mas não entra em nenhuma opção.

#atencao(titulo: "Efeitos colaterais da tokenização")[
  Como a pontuação é removida *dentro* da palavra, `shelf-life` vira `shelflif` e não casa com a consulta "shelf life" (é um dos casos do reranking, no @cap-hibrida). E a pontuação isolada vira o token vazio `""`, que aparece em 1.513 documentos; não afeta consultas comuns, mas entra no vocabulário.
]

No dev (BM25 com valores usuais), o NDCG\@10 foi 0,2655 sem etapas extras, 0,2713 só com stopwords, 0,2876 só com stemming e *0,2906 com os dois*. O stemming é o que mais ajuda; as stopwords quase não mudam a qualidade, mas cortam cerca de 20% dos postings. O sistema usa as duas etapas.

== Índice invertido

Para achar os documentos de um termo sem ler a coleção, guarda-se o mapeamento ao contrário, *termo → documentos*. A *posting list* de um termo lista os documentos em que ele aparece, com a frequência em cada um ($t f$). O índice também guarda as estatísticas do BM25: em quantos documentos cada termo aparece ($n_t$), o tamanho de cada documento ($|d|$), o número de documentos ($N$) e o tamanho total (para o tamanho médio, avgdl).

Exemplo com três documentos:

```python
# d1: "vitamin D and bone health"   d2: "vitamin D vitamin D deficiency in older adults falls"
# d3: "exercise prevents falls"
postings = {"vitamin": {"d1": 1, "d2": 2}, "fall": {"d2": 1, "d3": 1}, "bone": {"d1": 1}, ...}
document_frequencies = {"vitamin": 2, "fall": 2, ...}      # n_t
document_lengths = {"d1": 3, "d2": 6, "d3": 3}             # |d|; avgdl = 12 / 3 = 4
```

Uma consulta com 3 termos visita só 3 posting lists, e não os 3.633 documentos — é o que o enunciado exige. A classe `PostingList` implementa isso com dicionários (`termo → {doc_id: tf}`), que dão acesso em tempo constante; listas ordenadas só seriam necessárias para intercalar listas, como em buscas booleanas. Cada documento é inserido uma vez, atualizando postings, $n_t$, $|d|$ e o tamanho total de uma só vez.

No test: 3.633 documentos, 28.942 termos, 350.458 postings, construção em cerca de 7 s (quase tudo é pré-processamento).

== BM25

O BM25, do modelo probabilístico, pontua um documento somando a contribuição de cada termo da consulta:

$ "score"(d, q) = sum_(t in q) "IDF"(t) dot (t f(t, d) dot (k_1 + 1)) / (t f(t, d) + k_1 dot (1 - b + b dot (|d|) / "avgdl")), quad "IDF"(t) = log(1 + (N - n_t + 0.5) / (n_t + 0.5)) $

- *IDF*: termos raros pesam mais; o "$1 +$" mantém o IDF positivo mesmo para termos muito comuns.
- *$k_1$ (saturação)*: o peso cresce com o $t f$, mas cada ocorrência a mais vale menos; o termo nunca passa de $"IDF" dot (k_1 + 1)$. Usual: 1,2.
- *$b$ (normalização pelo tamanho)*: o fator $1 - b + b dot |d|\/"avgdl"$ penaliza documentos longos, que contêm os termos mais vezes sem serem mais relevantes. $b = 0$ desliga; $b = 1$ normaliza totalmente. Usual: 0,75.

*Exemplo* — consulta "vitamin falls" no índice acima ($k_1 = "1,2"$, $b = "0,75"$, $N = 3$, avgdl $= 4$). Os dois termos estão em 2 documentos: IDF $= log "1,6" = "0,4700"$.

- d2 ($|d| = 6$, fator de tamanho $"1,2" dot ("0,25" + "0,75" dot 6\/4) = "1,65"$): `vitamin` dá $"0,4700" dot (2 dot "2,2")\/(2 + "1,65") = "0,5666"$ e `fall` dá $"0,4700" dot "2,2"\/(1 + "1,65") = "0,3902"$; total *0,9568*.
- d1 e d3 ($|d| = 3$, fator $"0,975"$), um termo cada com $t f = 1$: *0,5235* cada — um empate.

=== Como a consulta é executada

A classe `ProbabilisticModel` (o BM25) guarda uma referência ao índice. Na consulta, ela pré-processa o texto com o mesmo pipeline, descarta termos fora do vocabulário e, *termo a termo*, percorre só a posting list de cada um, somando a contribuição em um acumulador por documento. Documentos sem nenhum termo da consulta nunca são visitados. $N$ e avgdl vêm do índice em tempo constante. No test, cada consulta visita em média 558 postings (0,16% do índice) e leva menos de 1 ms.

Consequência: o ranking lexical só contém documentos com algum termo da consulta. No test, 134 consultas recuperam menos de 100 documentos, e 16 não recuperam nenhum (todos os termos fora do vocabulário).

`LexicalIndex` junta o índice, as estatísticas (`IndexStats`) e o tempo de construção, e cria modelos BM25 com $k_1$ e $b$ diferentes *sem reconstruir o índice* — é assim que a grade é testada. `evaluate_bm25` roda todas as consultas, mede o tempo e calcula as métricas, devolvendo um `LexicalRun`.

#atencao(titulo: "Empates e a escolha de k1 e b")[
  O ranking é ordenado só pelo score. Em empate, vale a ordem em que os documentos entraram no acumulador (a ordem do `corpus.jsonl`): reprodutível, mas arbitrária. A grade $k_1 in {"0,5"; "1,2"; 2} times b in {0; "0,75"; 1}$ variou pouco no dev (NDCG\@10 entre 0,2854 e 0,2916), porque os documentos têm tamanhos parecidos. Com $b = 0$, porém, 93 das 324 consultas do dev tinham empate entre a 10ª e a 11ª posição, e a ordem de desempate mudava o NDCG\@10 em até 0,017; com $b = "0,75"$, só 3. Por isso o sistema usa os valores usuais, $k_1 = "1,2"$ e $b = "0,75"$.
]
