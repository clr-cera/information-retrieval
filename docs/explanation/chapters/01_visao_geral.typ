#import "../estilo.typ": *

= Visão geral

== O problema: recuperação de informação

Um sistema de Recuperação de Informação (RI) recebe uma *consulta* (o que o usuário quer saber) e devolve, de uma *coleção* de documentos, uma lista ordenada (*ranking*) dos documentos mais provavelmente úteis. Dois pontos definem o problema:

- o sistema não "entende" a necessidade do usuário diretamente: ele compara representações da consulta e dos documentos;
- a qualidade é medida comparando o ranking produzido com *julgamentos de relevância* feitos por pessoas (os *qrels*).

Este trabalho constrói e compara várias formas de fazer essa comparação, das mais clássicas às mais modernas.

== O pipeline do TP2

O enunciado pede um sistema que combine busca lexical e busca semântica, com reranking e geração de respostas (RAG):

```
                  ┌── pré-processamento → índice invertido → BM25 ───────┐
documentos ───────┤                                                     ├── RRF (híbrido) → reranking → top-5 → LLM → resposta
                  └── embeddings (bi-encoder) → similaridade do cosseno ┘
```

#tabela(
  (auto, 1fr),
  [*Etapa*], [*Ideia em uma frase*],
  [Pré-processamento], [Transformar texto em termos comparáveis (minúsculas, sem stopwords, com stemming).],
  [Índice invertido], [Para cada termo, guardar em quais documentos ele aparece e quantas vezes.],
  [BM25 (busca lexical)], [Pontuar documentos pela presença dos termos da consulta, dando mais peso a termos raros.],
  [Tolerância a erros], [Corrigir termos digitados errado antes da busca lexical.],
  [Busca semântica], [Representar consulta e documentos como vetores de significado e comparar os vetores.],
  [Busca híbrida (RRF)], [Combinar o ranking lexical e o semântico usando apenas as posições.],
  [Reranking], [Reordenar os 50 primeiros do híbrido com um modelo que lê consulta e documento juntos.],
  [RAG], [Dar os 5 melhores documentos a um modelo de linguagem para ele responder com base neles.],
)

Cada etapa tem um capítulo próprio neste documento. A etapa de RAG ainda não foi implementada; o que já existe para ela é descrito onde aparece (amostra fixa de consultas e formato do CSV).

== O conjunto de dados: NFCorpus

O NFCorpus é uma coleção da área de nutrição e saúde, distribuída pelo benchmark BEIR. Ele tem três tipos de arquivo:

- `corpus.jsonl`: os documentos. Cada linha é um JSON com `_id` (por exemplo, `MED-10`), `title` e `text`. Quase todos são resumos de artigos científicos da área médica. São *3.633 documentos*.
- `queries.jsonl`: as consultas. Cada linha tem `_id` (por exemplo, `PLAIN-68`) e `text`. O arquivo tem 3.237 consultas, de todos os splits juntos.
- `qrels/{train,dev,test}.tsv`: os julgamentos. Cada linha diz que um documento é relevante para uma consulta, com um grau.

#tabela(
  (auto, auto, auto, auto, 1fr),
  [*Split*], [*Consultas*], [*Julgamentos*], [*Relevantes por consulta*], [*Graus de relevância*],
  [train], [2.590], [110.575], [42,7 em média], [só grau 1],
  [dev], [324], [11.385], [35,1 em média (de 1 a 919)], [10.864 com grau 1 e 521 com grau 2],
  [test], [323], [12.334], [38,2 em média (de 1 a 475)], [11.758 com grau 1 e 576 com grau 2],
)

Os splits compartilham a mesma coleção de documentos; o que muda são as consultas e os julgamentos. As consultas de cada split são *apenas as que têm julgamentos no qrels daquele split*: por isso o código filtra o `queries.jsonl` (detalhes no @cap-dados).

#ideia(titulo: "Por que existem dev e test")[
  O conjunto *dev* serve para escolher configurações (pré-processamento, parâmetros do BM25, modelos, k do RRF). O conjunto *test* é usado só no final, para medir o desempenho da configuração já escolhida. Se as escolhas fossem feitas olhando o test, os números finais seriam otimistas, porque a configuração teria sido ajustada para aquelas consultas específicas. O enunciado proíbe usar os qrels do test para qualquer ajuste.
]

As consultas são *curtas*: em média 3,3 palavras no test (por exemplo, "Food Dyes and ADHD", "ECMO", "Finland"). Isso influencia muito o comportamento dos sistemas, como será visto ao longo do documento.

== Como ler este documento

- Os capítulos 2 e 3 mostram como o repositório está organizado e os recursos de Python que aparecem no código.
- Os capítulos 4 a 10 seguem o pipeline: métricas, dados, pré-processamento, índice e BM25, correção ortográfica, busca semântica, busca híbrida e reranking. Cada um começa pela teoria e depois passa pelo código, função por função.
- O capítulo 11 descreve os scripts que executam os experimentos; o 12, os testes e os resultados; o 13 reúne perguntas prováveis da defesa.

Nomes de arquivos, funções e variáveis aparecem em `fonte monoespaçada`. Os caminhos são relativos à raiz do repositório.
