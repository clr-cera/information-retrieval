# Validação do dataset e dos splits (etapa 1 do roadmap)

Saída de `uv run scripts/validate_experiment.py`, executado em 24/11/2026.

## Origem dos dados

O servidor oficial do BEIR (`public.ukp.informatik.tu-darmstadt.de`) estava inacessível (timeout). O loader usou
automaticamente a cópia do BEIR no Hugging Face, citada no enunciado. A origem fica registrada em `data/nfcorpus/SOURCE.txt`:

```
BeIR/nfcorpus@b5026a0e96e8a7ac4f95f482a596389289d46269 + BeIR/nfcorpus-qrels@a451b3b26d3ae1358f259c1a3a4dd61fcea35a65
```

Os arquivos são convertidos para o layout padrão do BEIR (`corpus.jsonl`, `queries.jsonl`, `qrels/{train,dev,test}.tsv`).

## Contagens por split

As consultas de cada split são apenas as que têm julgamento no qrels correspondente.

| Split | Documentos | Consultas com julgamento | Qrels |
|---|---|---|---|
| train | 3.633 | 2.590 | 110.575 |
| dev | 3.633 | 324 | 11.385 |
| test | 3.633 | 323 | 12.334 |

Os números conferem com o enunciado: 3.633 documentos e 323 consultas no test.

## Amostra fixa do RAG

Reproduzida com o código do enunciado (seed 42, consultas do test terminadas em "?"):

```
PLAIN-68, PLAIN-2450, PLAIN-153, PLAIN-2850, PLAIN-2750, PLAIN-270, PLAIN-2470, PLAIN-2430, PLAIN-238, PLAIN-3342
```

A lista é idêntica à do enunciado, o que também confirma que a cópia do Hugging Face tem o mesmo conteúdo do arquivo oficial.

## Conferência das métricas com o `ir_measures`

Calculadas sobre um ranking sintético (todos os julgados mais 30 documentos não julgados por consulta, embaralhados
com seed 0) nas 323 consultas do test. A diferença em relação ao `ir_measures` é ≤ 1e-12 em todas as métricas.

| Métrica | Valor | `ir_measures` |
|---|---|---|
| P@10 | 0,371207 | igual |
| R@10 | 0,203722 | igual |
| AP@10 (MAP@10) | 0,094068 | igual |
| NDCG@10 | 0,365271 | igual |

## Uso dos splits (auditoria do código)

- Todos os scripts de ajuste (`tune_lexical.py`, `tune_typo.py`, `tune_semantic.py`, `tune_hybrid.py`, `tune_reranker.py`)
  usam `--split dev` por padrão e escolhem o melhor valor por NDCG@10 médio no dev (ou acurácia de correção, no caso do `tune_typo.py`).
- O test só é usado por `run_retrieval_pipeline.py`, `run_lexical.py` e `run_typo.py`, que leem a configuração já congelada em
  `config/tp2_experiment.json` e não escolhem parâmetros.
- Únicos usos dos qrels do test para selecionar exemplos, ambos previstos no enunciado:
  - filtro NDCG@10 original > 0 no experimento de erros ortográficos (requisito 4.iii);
  - amostra fixa das 10 consultas do RAG (seed 42).
