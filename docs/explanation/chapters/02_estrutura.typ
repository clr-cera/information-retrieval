#import "../estilo.typ": *

= Estrutura do repositório

== Árvore de pastas

```
.
├── src/
│   ├── ir/                    biblioteca (pacote Python "ir"): toda a lógica
│   │   ├── metrics.py         métricas de avaliação
│   │   ├── data.py            dataset, configuração e escrita de resultados
│   │   ├── lexical.py         pré-processamento, índice invertido, BM25, correção ortográfica
│   │   ├── neural.py          busca semântica, RRF, reranking e montagem do pipeline
│   │   └── rag.py             prompts e chamada à LLM local (Ollama)
│   ├── scripts/               um programa por experimento ou análise
│   └── tests/                 testes (pytest), um arquivo por módulo
├── config/tp2_experiment.json configuração experimental congelada
├── data/                      dataset e cache de embeddings (gerados, fora do git)
├── result/tp2/                resultados (os finais são versionados)
├── docs/                      enunciado, checklist, pendências, histórico, relatório e esta explicação
├── tp1/                       Trabalho Prático 1 arquivado
├── pyproject.toml, uv.lock    dependências e versões exatas
```

A regra de organização: *a biblioteca `src/ir/` contém a lógica* e *os scripts só a usam* para rodar um experimento e gravar o resultado. Assim, o mesmo BM25 serve ao ajuste no dev, à avaliação no test, ao experimento de erros e às análises.

== Os cinco módulos da biblioteca

#tabela(
  (auto, 1fr, auto),
  [*Módulo*], [*Responsabilidade*], [*Depende de*],
  [`ir/metrics.py`], [P\@k, R\@k, AP\@k, NDCG\@k e Hit\@k, por consulta e médias (@cap-metricas).], [—],
  [`ir/data.py`], [Baixar e ler o NFCorpus, constantes do protocolo, leitura e gravação do config, escrita dos CSVs (@cap-dados).], [`metrics`],
  [`ir/lexical.py`], [Pré-processamento, índice invertido, BM25 e correção ortográfica (@cap-lexical e @cap-correcao).], [`metrics`],
  [`ir/neural.py`], [Busca semântica, RRF, reranking e montagem do pipeline a partir do config (@cap-semantica e @cap-hibrida).], [`metrics`, `data`, `lexical`],
  [`ir/rag.py`], [Prompts das condições sem e com RAG e chamada à LLM (@cap-rag).], [—],
)

A dependência é `metrics` ← `data` ← `lexical` ← `neural`, sem ciclos; `rag` é independente, e é o script `run_rag.py` que junta documentos recuperados e LLM. Os módulos foram formados juntando arquivos menores de uma organização anterior; comentários como `# Origem: src/posting_list.py` marcam de onde veio cada trecho.

O `pyproject.toml` declara o pacote `ir` dentro de `src/`. O comando `uv sync` cria o ambiente virtual com as versões do `uv.lock` e instala o projeto em *modo editável*: scripts e testes importam `ir` de qualquer pasta, e alterações no código valem na hora. A LLM não é dependência Python: roda no *Ollama*, um programa separado (`ollama pull qwen3:4b`).

== O arquivo de configuração

`config/tp2_experiment.json` registra o protocolo e as escolhas feitas no dev. Todos os scripts o leem; os de ajuste podem gravá-lo com `--update-config`.

```json
{
  "protocol": { "tuning_split": "dev", "final_split": "test", "evaluation_cutoff": 10,
                "ranking_depth": 100, "fusion_depth": 100, "rerank_depth": 50,
                "rrf_k_candidates": [10, 60, 100], "rag_query_seed": 42, "rag_query_ids": ["..."] },
  "selected": { "preprocessing": "WithStopRemovalWithStemming", "bm25_k1": 1.2, "bm25_b": 0.75,
                "typo_kgram_size": 2, "typo_jaccard_threshold": 0.2, "typo_edit_distance_threshold": 2,
                "embedding_model": "sentence-transformers/all-MiniLM-L6-v2", "rrf_k": 10,
                "reranker_model": "cross-encoder/ms-marco-MiniLM-L6-v2",
                "llm": "qwen3:4b", "llm_temperature": 0, "llm_max_tokens": 4096 }
}
```

`protocol` guarda os valores fixados pelo enunciado; `selected`, a escolha de cada componente.

#atencao(titulo: "Os parâmetros do BM25 foram fixados à mão")[
  `tune_lexical.py --update-config` gravaria $k_1 = 2$ e $b = 0$, o maior NDCG\@10 do dev. O grupo preferiu os valores usuais (1,2 e 0,75), porque a vantagem de $b = 0$ (0,001) é menor do que a variação causada por empates de score (até 0,017; ver @cap-lexical). Por isso, `tune_lexical.py` deve rodar *sem* `--update-config`.
]

== Pastas geradas e documentação

`data/` fica fora do git (grande e regenerável). Em `result/tp2/`, os arquivos finais são versionados, porque fazem parte da entrega.

#tabela(
  (auto, 1fr),
  [*Caminho*], [*Conteúdo*],
  [`data/nfcorpus/`], [O dataset e `SOURCE.txt` (de onde foi baixado).],
  [`data/embeddings/<modelo>/`], [Cache dos embeddings: matriz 3.633 × 384, ordem dos documentos e metadados.],
  [`result/tp2/results_*.csv`], [Os 100 primeiros documentos de cada consulta, para cada sistema.],
  [`result/tp2/metrics_per_query.csv`], [P\@10, R\@10, AP\@10 e NDCG\@10 por consulta e por sistema.],
  [`result/tp2/typo_experiment.csv`, `rag_experiment.csv`], [O experimento de erros ortográficos e as 20 respostas do RAG.],
  [`result/tp2/*_tuning_dev.csv`], [Os ajustes no dev.],
  [`result/tp2/*_stats.json`, `*_analysis.md`, `rag_stage_trace.md`], [Estatísticas, tempos e análises por consulta usadas no relatório.],
  [`result/tp2/rag_avaliacao/`], [Planilhas da avaliação humana, documentos por consulta e a chave.],
)

Em `docs/`: `enunciado_tp2.pdf`, `TP2_CHECKLIST.md` (cada requisito, feito ou pendente), `PENDENCIAS.md` (o que falta, passo a passo), `AVALIACAO_HUMANA_RAG.md` (guia da avaliação), `changes.md` (histórico), `experiment_protocol.md` (regras dos splits), `report/` (o relatório) e `explanation/` (este documento).
