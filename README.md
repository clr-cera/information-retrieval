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
| RAG (sem RAG × com RAG) | 20 respostas geradas e métricas do contexto calculadas; **avaliação humana pendente** |
| Arquivos padronizados de resultados | gerados e verificados; falta só a nota humana no `rag_experiment.csv` |
| Relatório | todas as seções escritas (15 de 20 páginas); faltam os itens que dependem da avaliação humana |

**O que falta fazer** está em [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md), passo a passo; a avaliação humana do RAG tem um guia próprio em [`docs/AVALIACAO_HUMANA_RAG.md`](docs/AVALIACAO_HUMANA_RAG.md). O acompanhamento de cada requisito do enunciado está em [`docs/TP2_CHECKLIST.md`](docs/TP2_CHECKLIST.md), e o histórico de alterações em [`docs/changes.md`](docs/changes.md).

## Estrutura do repositório

```
.
├── src/                         # todo o código do TP2
│   ├── ir/                      #   biblioteca (pacote Python)
│   │   ├── data.py              #     leitura do NFCorpus, configuração experimental, escrita dos CSVs
│   │   ├── metrics.py           #     P@k, R@k, AP@k, NDCG@k e Hit@k
│   │   ├── lexical.py           #     pré-processamento, índice invertido, BM25 e correção ortográfica
│   │   ├── neural.py            #     busca semântica, RRF, reranking e montagem do pipeline
│   │   └── rag.py               #     prompts e chamada à LLM local (Ollama)
│   ├── scripts/                 #   scripts executáveis (ajuste no dev e avaliação no test)
│   └── tests/                   #   testes (pytest), um arquivo por módulo de ir/
├── docs/                        # documentação e relatório
│   ├── enunciado_tp2.pdf        #   enunciado do trabalho
│   ├── TP2_CHECKLIST.md         #   checklist de todos os requisitos do enunciado
│   ├── changes.md               #   histórico de alterações
│   ├── experiment_protocol.md   #   protocolo experimental (uso dos splits, valores fixos)
│   ├── PENDENCIAS.md            #   o que falta o grupo fazer
│   ├── AVALIACAO_HUMANA_RAG.md  #   como fazer a avaliação humana do RAG
│   ├── report/                  #   relatório do TP2 (Typst)
│   └── explanation/             #   explicação do projeto: conceitos, pipeline e arquivos (Typst)
├── config/
│   └── tp2_experiment.json      # configuração experimental congelada (parâmetros escolhidos no dev)
├── tp1/                         # Trabalho Prático 1 arquivado (código, gráficos, relatório e app web)
├── data/                        # dataset e embeddings — gerados pelos scripts, fora do git
└── result/tp2/                  # resultados gerados pelos scripts (os arquivos finais são versionados)
```

Cada um dos quatro primeiros arquivos de `src/ir/` reúne vários módulos relacionados. Comentários `# Origem: src/<arquivo>.py` indicam de qual arquivo da organização anterior veio cada trecho.

| Módulo | Principais classes e funções |
|---|---|
| `src/ir/data.py` | `Document`, `Query`, `Qrel`, `NFCorpusSplit`, `load_split`, `select_rag_query_ids`, `load_experiment_config`, `write_ranking_csv`, `write_combined_metrics_csv`, `TypoExperimentRow`, `RagExperimentRow` |
| `src/ir/metrics.py` | `precision_at_k`, `recall_at_k`, `average_precision_at_k`, `ndcg_at_k`, `hit_at_k`, `compute_per_query_metrics`, `aggregate_metrics` |
| `src/ir/lexical.py` | `PipelineOptions`, `get_index_terms_freq`, `PostingList` (índice invertido), `ProbabilisticModel` (BM25), `LexicalIndex`, `evaluate_bm25`, `SpellingCorrector` |
| `src/ir/neural.py` | `SemanticIndex`, `evaluate_semantic`, `reciprocal_rank_fusion`, `CrossEncoderReranker`, `evaluate_reranker`, `build_lexical_run`, `build_semantic_run`, `build_hybrid_rankings` |
| `src/ir/rag.py` | `build_prompt_without_context`, `build_prompt_with_context`, `ask_llm`, `LLMAnswer` |

## Instalação

Requisitos: **Python 3.13**, [uv](https://docs.astral.sh/uv/) e, só para o RAG, o [Ollama](https://ollama.com) com o modelo `qwen3:4b`.

```bash
uv sync
ollama pull qwen3:4b      # só para o RAG (2,5 GB)
```

O `uv sync` cria o ambiente virtual, instala as dependências e instala o pacote `src/ir/` em modo editável, que os scripts e os testes importam. Na primeira execução, o NLTK baixa os recursos de stopwords e WordNet, e o Sentence Transformers baixa os modelos do Hugging Face.

### Dados

O NFCorpus é baixado automaticamente para `data/nfcorpus/` na primeira execução de qualquer script. Para usar outro diretório, defina `NFCORPUS_DIR`.

- Fonte principal: o arquivo oficial do BEIR (`nfcorpus.zip`, UKP/TU Darmstadt).
- Se esse servidor estiver fora do ar, o loader baixa a cópia do BEIR no Hugging Face (`BeIR/nfcorpus` e `BeIR/nfcorpus-qrels`, com revisões fixadas) e grava a origem usada em `data/nfcorpus/SOURCE.txt`.

Os embeddings dos documentos são calculados na primeira busca semântica e guardados em `data/embeddings/`.

## Execução

Todos os scripts leem a configuração de [`config/tp2_experiment.json`](config/tp2_experiment.json). Os scripts `tune_*` usam o conjunto **dev**; os `run_*` usam o **test** por padrão. Ordem recomendada:

```bash
# 1. Validar o dataset, a amostra do RAG e as métricas (comparadas com o ir_measures)
uv run src/scripts/validate_experiment.py

# 2. Ajustes no conjunto dev (--update-config grava a escolha no config)
uv run src/scripts/tune_lexical.py              # pré-processamento, k1 e b do BM25 (ver a observação abaixo)
uv run src/scripts/tune_typo.py --update-config # limiares da correção ortográfica
uv run src/scripts/tune_semantic.py --update-config
uv run src/scripts/tune_hybrid.py --update-config   # k do RRF
uv run src/scripts/tune_reranker.py --update-config # modelo do cross-encoder

# 3. Avaliação final no conjunto test
uv run src/scripts/run_retrieval_pipeline.py --split test   # lexical, semântico, híbrido e reranking
uv run src/scripts/run_typo.py                              # experimento de erros ortográficos
uv run src/scripts/analyze_typo.py                          # confere as regras do experimento e gera a tabela
uv run src/scripts/analyze_lexical_vs_semantic.py           # análise por consulta: lexical × semântico
uv run src/scripts/analyze_reranking.py                     # casos de ganho, sem alteração e piora do reranking

# 4. RAG (precisa do Ollama com o modelo qwen3:4b: `ollama pull qwen3:4b`)
uv run src/scripts/run_rag.py                               # respostas sem RAG (A) e com RAG (B), ~30 min em CPU
uv run src/scripts/evaluate_rag.py prepare                  # P@5/R@5/Hit@5, rastreamento por estágio e planilhas cegas
#    (cada integrante preenche result/tp2/rag_avaliacao/planilha_avaliadorN.csv sem abrir a chave)
uv run src/scripts/evaluate_rag.py merge --sheets result/tp2/rag_avaliacao/planilha_avaliador1.csv result/tp2/rag_avaliacao/planilha_avaliador2.csv

# 5. Conferência dos arquivos de resultados exigidos pelo enunciado
uv run src/scripts/check_results.py
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
| LLM (RAG) | **Qwen3 4B** (`qwen3:4b` no Ollama, quantizado em 4 bits), local, temperatura 0, seed 42; top-5 do reranking como contexto |

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
| `rag_experiment.csv` | pergunta, condição (A/B), documentos do contexto, prompt, resposta e as 4 notas com justificativas (as notas entram após a avaliação humana) |
| `*_tuning_dev.csv`, `*_stats.json`, `retrieval_summary.json` | ajustes no dev, estatísticas e tempos |
| `rag_retrieval_metrics.csv`, `rag_stage_trace.md`, `rag_generations.json` | P@5/R@5/Hit@5 do contexto, rastreamento por estágio e tempos da LLM |
| `*_analysis.md` | análises por consulta usadas no relatório |

Os arquivos finais do TP2 são versionados no git (as demais saídas não). Em `results_reranking.csv`, a coluna `score` tem o score do cross-encoder nas posições 1 a 50 e o score RRF nas posições 51 a 100: são escalas diferentes. Em `results_lexical.csv`, 134 consultas têm menos de 100 documentos (só documentos com algum termo da consulta são recuperados), e 16 não têm nenhum.

## Testes

```bash
uv run pytest             # testes do TP2 (src/tests/, 77 testes)
uv run pytest tp1/src     # testes do TP1 arquivado
```

## Ambiente

- **Linguagem:** Python 3.13
- **Principais bibliotecas:** nltk 3.10.3, numpy 2.5.3, torch 2.15.0, sentence-transformers 6.3.0, transformers 5.23.0, pandas 3.1.0, pyarrow 26.0.1, ir-measures 0.4.3 e pytest 9.1.1. As versões exatas de todas as dependências estão em `uv.lock`.
- **Hardware:** notebook com AMD Ryzen 7 5700U (8 núcleos / 16 threads) e 14 GB de RAM, execução em CPU, sem GPU.

## Relatório

O relatório do TP2 está em [`docs/report/`](docs/report/), escrito em [Typst](https://typst.app/):

```bash
typst compile docs/report/main.typ
```

Para estudar o projeto (por exemplo, para a defesa), há uma explicação em [`docs/explanation/`](docs/explanation/) (21 páginas): teoria de cada técnica, fluxo do pipeline, papel de cada arquivo e script, resultados e perguntas da defesa, com exemplos calculados. Para gerar o PDF:

```bash
typst compile docs/explanation/main.typ
```

## Trabalho Prático 1 (arquivado)

A pasta [`tp1/`](tp1/) guarda o TP1 sem alterações: modelos Vetorial e BM25 sobre o Cranfield (`tp1/src/`), gráficos (`tp1/plots/`), relatório (`tp1/report/`) e um aplicativo web de busca de letras de música (`tp1/web_backend/`, FastAPI; `tp1/web_ui/`, Rust/Leptos). Os scripts do TP1 usam caminhos relativos e devem ser executados de dentro de `tp1/`, por exemplo `cd tp1 && uv run src/main.py`.

## Licença

MIT — ver [`LICENSE`](LICENSE).
