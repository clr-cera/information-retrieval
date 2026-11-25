# Recuperação de Informação — Trabalho Prático 2

Sistema de Recuperação de Informação sobre o **NFCorpus** (benchmark BEIR) que combina busca lexical e semântica:

```
documentos → pré-processamento e índice invertido → BM25  ┐
                                                         ├→ fusão RRF → reranking (cross-encoder) → contexto → LLM (RAG)
documentos → embeddings (bi-encoder) → busca semântica  ┘
```

Trabalho da disciplina SCC0282 — Recuperação de Informação (ICMC/USP, 2º semestre de 2026, Prof. Marcelo Manzato).

## Integrantes

| Nome | Nº USP |
|---|---|
| Ariel Alves da Silva | 8847378 |
| Clara Ernesto de Carvalho | 14559479 |

## Estado do trabalho

| Etapa | Situação |
|---|---|
| Dataset e splits (NFCorpus/BEIR) | concluída |
| Pré-processamento e índice invertido próprio | concluída |
| Busca lexical (BM25) | concluída |
| Tolerância a erros (k-gramas, Jaccard, distância de edição) | concluída |
| Recuperação semântica (bi-encoder) | concluída |
| Busca híbrida (RRF) | concluída |
| Reranking (cross-encoder) | concluída |
| RAG (sem RAG × com RAG) | **pendente** |
| Relatório | em elaboração |

O acompanhamento detalhado de cada requisito do enunciado está em [`docs/TP2_CHECKLIST.md`](docs/TP2_CHECKLIST.md), e o histórico de alterações em [`docs/changes.md`](docs/changes.md).

## Estrutura do repositório

```
.
├── ir/                      # biblioteca do TP2 (pacote Python)
│   ├── data.py              #   leitura do NFCorpus, configuração experimental, escrita dos CSVs
│   ├── metrics.py           #   P@k, R@k, AP@k, NDCG@k e Hit@k
│   ├── lexical.py           #   pré-processamento, índice invertido, BM25 e correção ortográfica
│   └── neural.py            #   busca semântica, RRF, reranking e montagem do pipeline
├── scripts/                 # scripts executáveis (ajuste no dev e avaliação no test)
├── tests/                   # testes automatizados (pytest), um arquivo por módulo de ir/
├── config/
│   └── tp2_experiment.json  # configuração experimental congelada (parâmetros escolhidos no dev)
├── docs/                    # enunciado, checklist, protocolo experimental, validação do dataset, histórico
├── report/                  # relatório do TP2 (Typst)
├── tp1/                     # Trabalho Prático 1 arquivado (código, gráficos, relatório e app web)
├── data/                    # dataset e embeddings — gerados pelos scripts, não versionados
└── result/                  # resultados (CSVs e JSONs) — gerados pelos scripts, não versionados
```

Cada arquivo de `ir/` reúne vários módulos relacionados. Comentários `# Origem: src/...` marcam de qual arquivo antigo veio cada trecho.

| Módulo | Principais classes e funções |
|---|---|
| `ir/data.py` | `Document`, `Query`, `Qrel`, `NFCorpusSplit`, `load_split`, `select_rag_query_ids`, `load_experiment_config`, `write_ranking_csv`, `write_combined_metrics_csv`, `TypoExperimentRow`, `RagExperimentRow` |
| `ir/metrics.py` | `precision_at_k`, `recall_at_k`, `average_precision_at_k`, `ndcg_at_k`, `hit_at_k`, `compute_per_query_metrics`, `aggregate_metrics` |
| `ir/lexical.py` | `PipelineOptions`, `get_index_terms_freq`, `PostingList` (índice invertido), `ProbabilisticModel` (BM25), `LexicalIndex`, `evaluate_bm25`, `SpellingCorrector` |
| `ir/neural.py` | `SemanticIndex`, `evaluate_semantic`, `reciprocal_rank_fusion`, `CrossEncoderReranker`, `evaluate_reranker`, `build_lexical_run`, `build_semantic_run`, `build_hybrid_rankings` |

## Instalação

Requisitos: **Python 3.13** e [uv](https://docs.astral.sh/uv/).

```bash
uv sync
```

O `uv sync` cria o ambiente virtual, instala as dependências e instala o pacote `ir/` em modo editável, que os scripts e os testes importam. Na primeira execução, o NLTK baixa os recursos de stopwords e WordNet, e o Sentence Transformers baixa os modelos do Hugging Face.

### Dados

O NFCorpus é baixado automaticamente para `data/nfcorpus/` na primeira execução de qualquer script. Para usar outro diretório, defina `NFCORPUS_DIR`.

- Fonte principal: o arquivo oficial do BEIR (`nfcorpus.zip`, UKP/TU Darmstadt).
- Se esse servidor estiver fora do ar, o loader baixa a cópia do BEIR no Hugging Face (`BeIR/nfcorpus` e `BeIR/nfcorpus-qrels`, com revisões fixadas) e grava a origem usada em `data/nfcorpus/SOURCE.txt`.

Os embeddings dos documentos são calculados na primeira busca semântica e guardados em `data/embeddings/`.

## Execução

Todos os scripts leem a configuração de [`config/tp2_experiment.json`](config/tp2_experiment.json). Os scripts `tune_*` usam o conjunto **dev**; os `run_*` usam o **test** por padrão. Ordem recomendada:

```bash
# 1. Validar o dataset, a amostra do RAG e as métricas (comparadas com o ir_measures)
uv run scripts/validate_experiment.py

# 2. Ajustes no conjunto dev (--update-config grava a escolha no config)
uv run scripts/tune_lexical.py              # pré-processamento, k1 e b do BM25 (ver a observação abaixo)
uv run scripts/tune_typo.py --update-config # limiares da correção ortográfica
uv run scripts/tune_semantic.py --update-config
uv run scripts/tune_hybrid.py --update-config   # k do RRF
uv run scripts/tune_reranker.py --update-config # modelo do cross-encoder

# 3. Avaliação final no conjunto test
uv run scripts/run_retrieval_pipeline.py --split test   # lexical, semântico, híbrido e reranking
uv run scripts/run_typo.py                              # experimento de erros ortográficos
```

> **BM25:** os valores usuais (k1 = 1,2; b = 0,75) foram fixados à mão no config. O `tune_lexical.py --update-config` escolheria o maior NDCG@10 da grade (k1 = 2,0; b = 0), que está apenas 0,001 acima e cuja vantagem se deve a empates de score. A justificativa está em [`docs/experiment_protocol.md`](docs/experiment_protocol.md) e no relatório. Por isso, rode `tune_lexical.py` **sem** `--update-config`.

Os passos 2 já foram executados e o config está congelado: para reproduzir os resultados, basta o passo 3. O `run_retrieval_pipeline.py` leva cerca de 25 minutos em CPU, quase todo no reranking.

Tempos de referência (CPU, máquina descrita abaixo): construção do índice ~7 s; embeddings dos 3.633 documentos ~2,5 min (só na primeira vez); consulta lexical ~1 ms; consulta semântica ~0,16 s; reranking de 50 documentos ~4 s por consulta.

## Configuração final

| Componente | Escolha (ajustada no dev) |
|---|---|
| Representação dos documentos | título + texto, em todos os sistemas |
| Pré-processamento lexical | tokenização, minúsculas, remoção de stopwords (NLTK) e stemming de Porter |
| Modelo lexical | **BM25**, k1 = 1,2 e b = 0,75, sobre índice invertido próprio |
| Correção ortográfica | k-gramas com k = 2, Jaccard ≥ 0,2, distância de edição ≤ 2 |
| Modelo de embeddings | **`sentence-transformers/all-MiniLM-L6-v2`** (384 dimensões, cosseno, embeddings normalizados, máximo de 256 tokens) |
| Busca híbrida | Reciprocal Rank Fusion com **k = 10**, fundindo os 100 primeiros de cada sistema |
| Reranking | **`cross-encoder/ms-marco-MiniLM-L6-v2`** (máximo de 512 tokens), reordena os 50 primeiros do híbrido |
| LLM (RAG) | **a definir** |

## Resultados

Conjunto test (323 consultas), configuração final:

| Sistema | P@10 | R@10 | MAP@10 | NDCG@10 |
|---|---|---|---|---|
| Lexical (BM25) | 0,2307 | 0,1411 | 0,1109 | 0,3124 |
| Semântico | 0,2433 | 0,1550 | 0,1108 | 0,3167 |
| Híbrido (RRF) | 0,2557 | 0,1657 | 0,1259 | 0,3440 |
| Híbrido + reranking | 0,2505 | 0,1679 | 0,1382 | 0,3557 |

Experimento de erros ortográficos (10 consultas do test, sistema lexical): NDCG@10 médio de 0,471 na consulta original, 0,163 com o erro e 0,471 após a correção. As 10 correções recuperaram a palavra original.

Arquivos gerados em `result/tp2/`:

| Arquivo | Conteúdo |
|---|---|
| `results_lexical.csv`, `results_semantic.csv`, `results_hybrid.csv`, `results_reranking.csv` | 100 primeiros documentos por consulta: `query_id, doc_id, rank, score, relevance` |
| `metrics_per_query.csv` | `query_id, model, P10, R10, AP10, NDCG10` para os 4 sistemas |
| `typo_experiment.csv` | consultas original, com erro e corrigida, tipo do erro e os três NDCG@10 |
| `rag_experiment.csv` | pendente (etapa de RAG) |
| `*_tuning_dev.csv`, `*_stats.json`, `retrieval_summary.json` | ajustes no dev, estatísticas e tempos |

## Testes

```bash
uv run pytest             # testes do TP2 (tests/)
uv run pytest tp1/src     # testes do TP1 arquivado
```

## Ambiente

- **Linguagem:** Python 3.13
- **Principais bibliotecas:** nltk 3.10.3, numpy 2.5.3, torch 2.15.0, sentence-transformers 6.3.0, transformers 5.23.0, pandas 3.1.0, pyarrow 26.0.1, ir-measures 0.4.3 e pytest 9.1.1. As versões exatas de todas as dependências estão em `uv.lock`.
- **Hardware:** notebook com AMD Ryzen 7 5700U (8 núcleos / 16 threads) e 14 GB de RAM, execução em CPU, sem GPU.

## Relatório

O relatório do TP2 está em [`report/`](report/), escrito em [Typst](https://typst.app/):

```bash
typst compile report/main.typ
```

## Trabalho Prático 1 (arquivado)

A pasta [`tp1/`](tp1/) guarda o TP1 sem alterações: modelos Vetorial e BM25 sobre o Cranfield (`tp1/src/`), gráficos (`tp1/plots/`), relatório (`tp1/report/`) e um aplicativo web de busca de letras de música (`tp1/web_backend/`, FastAPI; `tp1/web_ui/`, Rust/Leptos). Os scripts do TP1 usam caminhos relativos e devem ser executados de dentro de `tp1/`, por exemplo `cd tp1 && uv run src/main.py`.

## Licença

MIT — ver [`LICENSE`](LICENSE).
