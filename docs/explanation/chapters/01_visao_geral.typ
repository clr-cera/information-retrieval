#import "../estilo.typ": *

= Visão geral

== O problema e o pipeline

Um sistema de Recuperação de Informação recebe uma *consulta* e devolve, de uma *coleção*, uma lista ordenada (*ranking*) dos documentos mais provavelmente úteis. A qualidade é medida comparando esse ranking com *julgamentos de relevância* feitos por pessoas (os *qrels*). O TP2 constrói e compara várias formas de produzir esse ranking e, no fim, usa o melhor delas para alimentar um modelo de linguagem (RAG):

```
                  ┌── pré-processamento → índice invertido → BM25 ───────┐
documentos ───────┤                                                     ├── RRF (híbrido) → reranking → top-5 → LLM → resposta
                  └── embeddings (bi-encoder) → similaridade do cosseno ┘
```

#tabela(
  (auto, 1fr, auto),
  [*Etapa*], [*Ideia em uma frase*], [*Capítulo*],
  [Pré-processamento + índice + BM25], [Transformar o texto em termos, indexá-los e pontuar documentos pelos termos da consulta, com mais peso para termos raros.], [@cap-lexical],
  [Correção ortográfica], [Trocar termos digitados errado pela palavra mais parecida do vocabulário.], [@cap-correcao],
  [Busca semântica], [Representar consulta e documentos como vetores de significado e comparar os vetores.], [@cap-semantica],
  [Busca híbrida (RRF)], [Combinar o ranking lexical e o semântico usando só as posições.], [@cap-hibrida],
  [Reranking], [Reordenar os 50 primeiros do híbrido com um modelo que lê consulta e documento juntos.], [@cap-hibrida],
  [RAG], [Dar os 5 melhores documentos a uma LLM para ela responder com base neles.], [@cap-rag],
)

Todas as etapas estão implementadas, executadas e avaliadas.

== O conjunto de dados: NFCorpus

Coleção de nutrição e saúde do benchmark BEIR, com três tipos de arquivo:

- `corpus.jsonl`: *3.633 documentos*, quase todos resumos de artigos médicos, com `_id` (como `MED-10`), `title` e `text`;
- `queries.jsonl`: 3.237 consultas de todos os splits, com `_id` (como `PLAIN-68`) e `text`;
- `qrels/{train,dev,test}.tsv`: os julgamentos (consulta, documento, grau).

#tabela(
  (auto, auto, auto, 1fr),
  [*Split*], [*Consultas*], [*Relevantes por consulta*], [*Graus*],
  [train], [2.590], [42,7 em média], [só grau 1],
  [dev], [324], [35,1 em média], [grau 1 e grau 2],
  [test], [323], [38,2 em média], [grau 1 e grau 2],
)

Os splits compartilham a coleção; mudam as consultas e os julgamentos. Cada split usa *só as consultas que têm julgamento* nele, por isso o código filtra o `queries.jsonl`. As consultas são curtas (3,3 palavras em média no test, como "Food Dyes and ADHD" ou "ECMO"), o que pesa no comportamento de todos os sistemas.

#ideia(titulo: "Por que existem dev e test")[
  O *dev* serve para escolher configurações (pré-processamento, parâmetros, modelos, $k$ do RRF). O *test* só mede a configuração já escolhida. Escolher olhando o test deixaria os números finais otimistas; o enunciado proíbe usar os qrels do test para qualquer ajuste.
]

== Como ler este documento

Os capítulos 2 a 4 cobrem a organização do repositório, as métricas e a camada de dados. Os capítulos 5 a 9 seguem o pipeline: cada um apresenta a teoria, um exemplo calculado, o que o arquivo de código faz e a escolha feita no dev. O capítulo 10 mostra a ordem de execução dos scripts; o 11, os testes e os resultados; o 12 reúne perguntas prováveis da defesa. Caminhos são relativos à raiz do repositório.
