#import "../estilo.typ": *

= Estrutura do repositório

== Árvore de pastas

```
.
├── src/                         todo o código do TP2
│   ├── ir/                      biblioteca (pacote Python chamado "ir")
│   │   ├── __init__.py          marca a pasta como pacote
│   │   ├── metrics.py           métricas de avaliação
│   │   ├── data.py              dados, configuração e escrita de resultados
│   │   ├── lexical.py           pré-processamento, índice invertido, BM25, correção ortográfica
│   │   └── neural.py            busca semântica, RRF, reranking e montagem do pipeline
│   ├── scripts/                 programas executáveis (um por experimento)
│   └── tests/                   testes automatizados (pytest)
├── config/tp2_experiment.json   configuração experimental congelada
├── docs/                        enunciado, checklist, histórico, protocolo, relatório e esta explicação
├── tp1/                         Trabalho Prático 1 arquivado
├── data/                        dataset e embeddings (gerados, fora do git)
├── result/tp2/                  resultados dos experimentos (gerados, fora do git)
├── pyproject.toml               dependências e configuração do pacote
└── uv.lock                      versões exatas de todas as dependências
```

A separação segue uma regra simples: *a biblioteca (`src/ir/`) contém a lógica*, e *os scripts (`src/scripts/`) só a usam* para rodar um experimento e salvar o resultado. Assim, o mesmo código de BM25 serve ao ajuste no dev, à avaliação no test e ao experimento de erros.

== Os quatro módulos da biblioteca

#tabela(
  (auto, 1fr, auto),
  [*Módulo*], [*Responsabilidade*], [*Depende de*],
  [`ir/metrics.py`], [P\@k, R\@k, AP\@k, NDCG\@k e Hit\@k, por consulta e médias.], [nada do projeto],
  [`ir/data.py`], [Baixar e ler o NFCorpus, guardar caminhos e constantes do protocolo, ler e gravar o arquivo de configuração e escrever os CSVs.], [`metrics`],
  [`ir/lexical.py`], [Pré-processamento, índice invertido (`PostingList`), BM25 (`ProbabilisticModel`), avaliação lexical e correção ortográfica.], [`metrics`],
  [`ir/neural.py`], [Busca semântica (`SemanticIndex`), RRF, reranking (`CrossEncoderReranker`) e funções que montam o pipeline a partir da configuração.], [`metrics`, `data`, `lexical`],
)

A ordem de dependência é `metrics` ← `data` ← `lexical` ← `neural`, sem ciclos: um módulo nunca importa outro que dependa dele.

Os módulos foram formados juntando arquivos menores de uma organização anterior. Comentários como `# Origem: src/posting_list.py` marcam de onde veio cada trecho; por isso alguns arquivos repetem imports no meio (cada trecho mantém os seus), o que não altera o funcionamento.

== Como o pacote `ir` fica disponível

Os scripts fazem `from ir.lexical import LexicalIndex`. Para o Python encontrar o pacote `ir`, o `pyproject.toml` declara:

```toml
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[tool.setuptools]
package-dir = {"" = "src"}   # os pacotes ficam dentro de src/
packages = ["ir"]            # o único pacote é ir

[tool.pytest.ini_options]
testpaths = ["src/tests"]    # onde o pytest procura testes
```

O comando `uv sync` cria um ambiente virtual (`.venv/`), instala as dependências com as versões do `uv.lock` e instala o próprio projeto em *modo editável*: em vez de copiar os arquivos, o ambiente aponta para `src/ir/`. Com isso, qualquer alteração no código vale imediatamente, e scripts e testes conseguem importar `ir` de qualquer pasta.

== O arquivo de configuração

`config/tp2_experiment.json` registra o protocolo e as escolhas feitas no dev. Todos os scripts o leem; os scripts de ajuste podem gravá-lo (opção `--update-config`).

```json
{
  "status": "retrieval_tuned",
  "protocol": {
    "dataset": "NFCorpus", "document_representation": "title + text",
    "tuning_split": "dev", "final_split": "test",
    "evaluation_cutoff": 10, "ranking_depth": 100, "fusion_depth": 100, "rerank_depth": 50,
    "rrf_k_candidates": [10, 60, 100],
    "rag_query_seed": 42, "rag_query_sample_size": 10, "rag_query_ids": ["PLAIN-68", "..."]
  },
  "selected": {
    "preprocessing": "WithStopRemovalWithStemming", "lexical_model": "BM25",
    "bm25_k1": 1.2, "bm25_b": 0.75,
    "typo_kgram_size": 2, "typo_jaccard_threshold": 0.2, "typo_edit_distance_threshold": 2,
    "embedding_model": "sentence-transformers/all-MiniLM-L6-v2",
    "rrf_k": 10, "reranker_model": "cross-encoder/ms-marco-MiniLM-L6-v2",
    "llm": null, "llm_temperature": 0, "llm_max_tokens": null, "rag_language": null
  }
}
```

- `protocol`: valores fixos pelo enunciado (cortes, profundidades, candidatos de k, amostra do RAG). Não mudam.
- `selected`: as escolhas. `null` significa "ainda não escolhido" (os campos do RAG).

#atencao(titulo: "Os parâmetros do BM25 foram fixados à mão")[
  `tune_lexical.py --update-config` gravaria k1 = 2,0 e b = 0, o maior NDCG\@10 do dev. O grupo preferiu os valores usuais (1,2 e 0,75) porque a vantagem de b = 0 (0,001) é menor do que a variação causada por empates de score (até 0,017). Por isso, `tune_lexical.py` deve ser rodado *sem* `--update-config` (ver o @cap-bm25).
]

== Pastas geradas: `data/` e `result/`

Essas pastas não vão para o git (estão no `.gitignore`) porque são grandes e podem ser recriadas pelos scripts.

#tabela(
  (auto, 1fr),
  [*Caminho*], [*Conteúdo*],
  [`data/nfcorpus/`], [`corpus.jsonl`, `queries.jsonl`, `qrels/*.tsv` e `SOURCE.txt` (de onde o dataset foi baixado).],
  [`data/embeddings/<modelo>/`], [`document_embeddings.npy` (matriz 3.633 × 384), `document_ids.json` (ordem das linhas) e `metadata.json`.],
  [`result/tp2/results_*.csv`], [Os 100 primeiros documentos de cada consulta para cada sistema.],
  [`result/tp2/metrics_per_query.csv`], [P\@10, R\@10, AP\@10 e NDCG\@10 por consulta e por sistema.],
  [`result/tp2/typo_experiment.csv`], [O experimento de erros ortográficos.],
  [`result/tp2/*_tuning_dev.csv`], [Os resultados dos ajustes no dev.],
  [`result/tp2/*_stats.json`, `retrieval_summary.json`], [Estatísticas do índice, tempos e médias.],
)

== Documentação em `docs/`

#tabela(
  (auto, 1fr),
  [*Arquivo*], [*Para que serve*],
  [`enunciado_tp2.pdf`], [O enunciado do trabalho.],
  [`TP2_CHECKLIST.md`], [Cada requisito do enunciado, marcado como feito ou pendente.],
  [`changes.md`], [Histórico de todas as alterações, com o motivo e a verificação.],
  [`experiment_protocol.md`], [Regras de uso dos splits e valores fixos do protocolo.],
  [`dataset_validation.md`], [Contagens do dataset e conferência das métricas.],
  [`report/`], [O relatório do trabalho, em Typst.],
  [`explanation/`], [Este documento.],
)
