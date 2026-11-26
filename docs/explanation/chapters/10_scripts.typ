#import "../estilo.typ": *

= Os scripts e o fluxo de execução (`src/scripts/`) <cap-scripts>

Cada script roda com `uv run src/scripts/<nome>.py` e segue o mesmo esquema: ler as opções (`argparse`), ler o config, carregar o split, chamar a biblioteca `ir`, gravar em `results/` e imprimir um resumo.

== Ordem de execução

```
1. validate_experiment.py                  confere dataset, amostra do RAG e métricas
2. tune_lexical.py → tune_typo.py → tune_semantic.py → tune_hybrid.py → tune_reranker.py   (dev)
3. run_retrieval_pipeline.py               os quatro sistemas no test
   run_typo.py, analyze_*.py               experimento de erros e análises por consulta
4. run_rag.py                              respostas sem e com RAG (precisa do Ollama)
   evaluate_rag.py prepare                 métricas do contexto, rastreamento, planilhas cegas
   (avaliação humana)
   evaluate_rag.py merge --sheets ...      junta as notas
5. check_results.py                        confere os arquivos exigidos pelo enunciado
```

Os ajustes só gravam a escolha no config com `--update-config`, e a ordem importa: o ajuste do RRF usa o lexical e o semântico já escolhidos, e o do reranker usa o híbrido.

== O que cada script faz

#tabela(
  (auto, auto, 1fr),
  [*Script*], [*Split*], [*O que faz*],
  [`validate_experiment.py`], [todos], [Imprime o tamanho dos splits, refaz o sorteio do RAG e compara as métricas do projeto com o `ir_measures` em rankings artificiais.],
  [`tune_lexical.py`], [dev], [Para cada uma das 4 opções de pré-processamento, constrói o índice uma vez e avalia a grade de $k_1$ e $b$ → `lexical_tuning_dev.csv`. Rodar *sem* `--update-config` (ver @cap-lexical).],
  [`tune_typo.py`], [dev], [Gera 200 erros simulados e mede a acurácia de cada configuração do corretor → `typo_tuning_dev.csv`.],
  [`tune_semantic.py`], [dev], [Compara os dois bi-encoders → `semantic_tuning_dev.csv`.],
  [`tune_hybrid.py`], [dev], [Testa $k in {10, 60, 100}$ no RRF → `hybrid_tuning_dev.csv`.],
  [`tune_reranker.py`], [dev], [Compara os dois cross-encoders sobre o híbrido → `reranker_tuning_dev.csv`.],
  [`run_retrieval_pipeline.py`], [test], [A avaliação final: roda lexical, semântico, híbrido e reranking com o config e grava os quatro `results_*.csv`, o `metrics_per_query.csv`, as estatísticas e o `retrieval_summary.json`. Em outro split, grava numa subpasta, para não sobrescrever os resultados oficiais. Leva cerca de 25 min em CPU, quase tudo no reranking.],
  [`run_lexical.py`], [test], [Roda só o BM25, com opções para sobrescrever pipeline, $k_1$, $b$ e as saídas.],
  [`run_typo.py`], [test], [O experimento de erros ortográficos (@cap-correcao) → `typo_experiment.csv`.],
  [`analyze_typo.py`], [test], [Confere as regras do experimento de erros e monta a tabela → `typo_analysis.md`.],
  [`analyze_lexical_vs_semantic.py`], [test], [Escolhe as 3 consultas em que cada sistema mais ganha do outro e reúne a evidência: termos e $n_t$, relevantes alcançáveis pelo BM25, top-5 de cada sistema com termos casados e truncamento → `lexical_vs_semantic_analysis.md`.],
  [`analyze_reranking.py`], [test], [Escolhe os 2 maiores ganhos, 1 caso sem alteração e a maior piora do reranking e lista as posições antes e depois → `reranking_analysis.md`.],
  [`run_rag.py`, `evaluate_rag.py`], [test], [Geração e avaliação do RAG (@cap-rag).],
  [`check_results.py`], [test], [Verifica os 7 arquivos exigidos (colunas, até 100 documentos por consulta, posições sem buracos, relevância igual aos qrels, 10 consultas no experimento de erros, 20 linhas e notas no RAG). Hoje, o único problema é a falta das notas humanas.],
)

#atencao(titulo: "Cuidado com run_lexical.py")[
  Sem `--metrics-output`, ele sobrescreve o `metrics_per_query.csv` oficial *só com o lexical*, apagando os outros três sistemas. Para medir só o lexical, redirecione as saídas.
]
