# Registro de alterações (TP2)

Alterações feitas no repositório, da mais recente para a mais antiga. Cada entrada diz o que mudou, por quê e como foi verificado.

---

## 25/11/2026 — Requisito 4 (tolerância a erros)

- **Novo script `src/scripts/analyze_typo.py`:** lê `result/tp2/typo_experiment.csv` e confere as regras do enunciado em cada consulta:
  - NDCG@10 original maior que zero;
  - exatamente um termo alterado;
  - termo com erro fora do dicionário e termo original dentro dele;
  - nenhuma correção indevida.

  Ele também monta a tabela por consulta, as médias e a contagem por tipo de erro. Nas consultas em que o erro não reduziu o NDCG@10, mostra o top-5 das duas versões e o número de documentos de cada termo. A saída vai para `result/tp2/typo_analysis.md`. Escrito em estilo convencional (laços explícitos, funções pequenas, sem atalhos).
- **Código existente não alterado:** a implementação da correção (`SpellingCorrector`, em `src/ir/lexical.py`) e os scripts `run_typo.py` e `tune_typo.py` ficaram como estavam.
- **`tune_typo.py` reexecutado no dev, sem `--update-config`:** gerou `result/tp2/typo_tuning_dev.csv` com a mesma escolha do config (k = 2, Jaccard ≥ 0,2, distância ≤ 2; 92,0% de acerto).
- **Relatório:**
  - `docs/report/chapters/methodology/typo_tolerance.typ`: dicionário, algoritmo em três etapas, ajuste no dev com tabela, protocolo do experimento e o item opcional (sistema semântico) registrado como não feito;
  - `docs/report/chapters/results/typo_tolerance.typ`: tabela das 10 consultas, médias, impacto do erro e os dois casos em que o erro aumentou o NDCG@10 (`practices` e `disruptors`), explicados com contagens medidas.
- **Verificação das explicações:** foram feitas com um script no scratchpad, só com consultas do experimento. Exemplos: dos 183 documentos com `practic`, só 13 são relevantes; dos 13 documentos com `disruptor`, só 4 são relevantes; o top-10 passa de 5 para 7 relevantes e de 3 para 5, respectivamente.
- `docs/TP2_CHECKLIST.md`: seção 4 marcada como concluída.

## 25/11/2026 — Raiz do repositório enxugada

A raiz passou de 13 itens para 6 pastas e 4 arquivos. `data/` e `result/` continuam gerados e fora do git.

```
src/     ir/, scripts/, tests/        (antes: ir/, scripts/ e tests/ na raiz)
docs/    documentos + report/          (antes: report/ na raiz)
config/  tp1/  data/  result/
README.md  LICENSE  pyproject.toml  uv.lock
```

- **Única mudança no código:** `PROJECT_ROOT` (2 ocorrências em `src/ir/data.py`) e `OFFICIAL_DATA_DIR` (`src/tests/test_data.py`) passaram de `Path(__file__).resolve().parent.parent` para `.parents[2]`, porque os arquivos desceram um nível. Os caminhos de `data/`, `result/`, `config/` e dos embeddings continuam os mesmos.
- **`pyproject.toml`:** `package-dir = {"" = "src"}` e `testpaths = ["src/tests"]`.
- **graphify removido:** `graphify-out/`, `.graphifyignore` e a entrada no `.gitignore`. Era só uma ferramenta de navegação, não parte do trabalho, e o grafo já estava desatualizado.
- **Artefatos gerados apagados:** `information_retrieval.egg-info/` e `.pytest_cache/` (recriados automaticamente).
- **Referências de caminhos atualizadas:** README (árvore reescrita), `docs/TP2_CHECKLIST.md`, `docs/dataset_validation.md` e seções do relatório.
- **Relatório:** recompilado no novo lugar (`typst compile docs/report/main.typ`), o que também atualizou o `main.pdf`, que estava desatualizado.
- **Verificação:**
  - `uv run pytest`: 74 testes passando; o teste que usa o dataset real rodou, sem ser pulado;
  - `uv run pytest tp1/src`: 27 testes passando;
  - `src/scripts/validate_experiment.py` passou;
  - os 9 scripts respondem a `--help`;
  - `ir.data` aponta para a raiz do projeto.

## 25/11/2026 — Reorganização do repositório

**Nova estrutura** (detalhada no README):

```
ir/        biblioteca do TP2: data.py, metrics.py, lexical.py, neural.py
scripts/   9 scripts executáveis (tune_*, run_*, validate_experiment)
tests/     test_data.py, test_metrics.py, test_lexical.py, test_neural.py
config/    docs/    report/    tp1/    (data/ e result/ continuam gerados e não versionados)
```

- **Módulos fundidos (15 → 4)**, por concatenação e sem mudar a lógica:
  - `ir/data.py` ← `nfcorpus_loader`, `experiment_config`, `results_io`
  - `ir/metrics.py` ← `metrics`
  - `ir/lexical.py` ← `document_processor`, `posting_list`, `probabilistic_model`, `lexical_index`, `lexical_retrieval`, `typo_correction`
  - `ir/neural.py` ← `semantic_retrieval`, `hybrid`, `reranker`, `retrieval_components`
  - Cada trecho tem um comentário `# Origem: src/<arquivo>.py`.
  - **Únicas mudanças no código:**
    - os imports entre módulos fundidos foram reescritos para `ir.<módulo>` ou removidos quando o nome já está no mesmo arquivo;
    - um único `from __future__ import annotations` por arquivo;
    - a constante de teste `DOCUMENTS` do antigo `lexical_index_test.py` foi renomeada para `INDEX_DOCUMENTS`, porque colidia com a de `posting_list_test.py`, que tem outro conteúdo.
  - `PROJECT_ROOT` aparece duas vezes em `ir/data.py`, com o mesmo valor. Os caminhos (`data/`, `result/`, `config/`) continuam os mesmos, porque `ir/` está na mesma profundidade que o antigo `src/`.
- **Testes fundidos (12 → 4)** em `tests/`. O teste do modelo vetorial (`models_test.py`) foi para o TP1.
- **Scripts** movidos para `scripts/` sem mudanças além dos imports.
- **`pyproject.toml`:** `[build-system]` (setuptools) e `packages = ["ir"]`, para o `uv sync` instalar o pacote em modo editável; `[tool.pytest.ini_options] testpaths = ["tests"]`.
- **TP1 arquivado em `tp1/`:**
  - `src/`: `main.py`, `experiments.py`, `plots.py`, `get_discrepant_queries.py`, `vectorial_model.py` e `models_test.py`, mais **cópias** de `document_processor.py`, `posting_list.py`, `probabilistic_model.py` e dos testes deles, para o TP1 continuar funcionando sozinho;
  - `analysis.py`, `plots/`, `report/` (antes `report-tp1/`), `web_backend/` e `web_ui/`;
  - `README.md`: o README antigo, que documentava a API do TP1.
- **Outros movimentos:** `report-tp2/` → `report/`; `Trabalho_Pratico_2_RI_2026.pdf` → `docs/enunciado_tp2.pdf`.
- **`.gitignore`:** adicionado `graphify-out/`.
- **README reescrito** para o projeto inteiro: integrantes, estado, estrutura, instalação, dados, ordem de execução, configuração final, resultados, testes, ambiente, relatório e TP1.
- **Referências de caminhos atualizadas** em `docs/TP2_CHECKLIST.md`, `docs/dataset_validation.md` e nas seções do relatório. As entradas antigas deste histórico mantêm os nomes da época.
- **Verificação:**
  - `uv run pytest`: 74 testes passando (os 2 que faltam em relação aos 76 anteriores são do modelo vetorial, agora no TP1);
  - `uv run pytest tp1/src`: 27 testes passando;
  - `scripts/validate_experiment.py` passou;
  - `scripts/run_lexical.py --split dev` reproduziu o NDCG@10 do dev (0,2906);
  - os 9 scripts respondem a `--help`.
- O grafo do graphify (`graphify-out/`) ficou desatualizado, porque se refere aos caminhos antigos. Regenerar com `/graphify` se for usado.

---

## 25/11/2026 — BM25 com os valores usuais (k1 = 1,2; b = 0,75) e reexecução

- `config/tp2_experiment.json`: `bm25_k1` 2.0 → 1.2 e `bm25_b` 0.0 → 0.75, por decisão do grupo baseada no dev. Com b = 0, os empates de score fazem a ordem de desempate mover o NDCG@10 do dev em até 0,017, contra uma vantagem de 0,001 sobre os valores usuais.
- Reexecução, nesta ordem:
  - `tune_hybrid.py --update-config` (dev): RRF k = 10 mantido (NDCG@10 dev 0,3299);
  - `tune_reranker.py --update-config` (dev): `ms-marco-MiniLM-L6-v2` mantido (0,3310);
  - `run_retrieval_pipeline.py --split test`;
  - `run_typo.py`.
- Resultados antigos (k1 = 2,0; b = 0) guardados em `result/tp2/old_k2_b0/`.
- Test, NDCG@10:
  - lexical: 0,3124
  - semântico: 0,3167
  - híbrido: 0,3440
  - reranking: 0,3557
- Erros ortográficos: recuperação média de 100%; 2 consultas em que o erro não reduziu o desempenho.
- Relatório:
  - `lexical.typ`: seção de parâmetros reescrita para os valores usuais, e comparação BM25 × TF-IDF recalculada com eles (0,2906 × 0,2880; 82 × 86 consultas vencidas);
  - `preprocessing.typ` e `inverted_index.typ`: parâmetros e tempos atualizados (construção em 7,32 s; 0,90 ms por consulta).
- `docs/experiment_protocol.md` e checklist atualizados.

## 25/11/2026 — Estrutura do relatório do TP2

- `report-tp2/main.typ`:
  - **capa em português:** os rótulos fixos do template ("STUDENT", "INSTRUCTOR", "DATE") viraram "AUTORES", "PROFESSOR" e "DATA"; a data saiu em português; o professor foi adicionado; os emails foram para uma linha própria abaixo do título, e o rodapé mostra só os nomes;
  - **títulos numerados (1, 1.1, 1.1.1):** os três níveis de título foram redefinidos com o mesmo estilo e as cores do tema, porque o template mostra só o texto do título;
  - **sumário** limitado a dois níveis;
  - sem justificação de texto nas grades (capa, cabeçalho e rodapé), que têm colunas estreitas.
- **Seções pendentes visíveis:** as subseções ainda não escritas (`chapters/methodology/*`, `chapters/results/*`, `evaluation.typ` com 5 subseções, `introduction.typ`, `conclusion.typ`, `ai_use.typ`) agora têm o título real e a linha "Seção em elaboração.", em vez de só um comentário. Assim, o sumário mostra toda a estrutura exigida pelo enunciado.
- O conteúdo das seções já escritas não mudou.

## 25/11/2026 — Requisito 3 (busca lexical): seção do relatório

- `report-tp2/chapters/methodology/lexical.typ` completado:
  - **Escolha do modelo:** justificativa do BM25 com o resultado do TP1 e uma comparação no dev do NFCorpus (BM25 NDCG@10 = 0,2916 contra 0,2880 do TF-IDF com cosseno; 88 contra 85 consultas vencidas e 151 empates). O texto assume que a vantagem é pequena.
  - **Função de ranqueamento:** fórmula do BM25 e do IDF, e uso do índice.
  - **Empates de score:** o item opcional do checklist (desempate explícito) **não** foi implementado, mas está discutido. Inclui a tabela de sensibilidade do NDCG@10 do dev à ordem de desempate.
- Medições auxiliares feitas com scripts no scratchpad, só com o dev para decisões:
  - TF-IDF com cosseno sobre o vetor completo do documento. O `vectorial_model.py` do TP1 calcula a norma só com os termos da consulta e **não** foi alterado.
  - Contagem de empates no BM25 e sensibilidade das métricas à ordem de desempate.
- `docs/TP2_CHECKLIST.md`: seção 3 marcada como concluída; o desempate explícito ficou como opcional não implementado.
- **Achado:** com b = 0, os empates tornam a vantagem de 0,001 sobre os valores usuais irrelevante. A ordem de desempate sozinha faz o NDCG@10 do dev variar 0,017. Ver a decisão pendente sobre b no checklist.
- Nenhum código foi alterado.

---

## 25/11/2026 — Requisito 2 (índice invertido): estatísticas e seção do relatório

- `result/tp2/lexical_stats.json` regerado com o BM25 novo, via `uv run src/run_lexical.py --split test` com `--rankings-output` e `--metrics-output` apontando para o scratchpad, para não sobrescrever o `results_lexical.csv` e o `metrics_per_query.csv` combinados.
  - Resultado: 3.633 documentos, vocabulário de 28.942 termos, 350.458 postings, construção em 5,95 s e 0,56 ms por consulta.
  - Ranking e métricas idênticos aos da execução anterior (NDCG@10 = 0,3137).
- `report-tp2/chapters/methodology/inverted_index.typ` escrito:
  - estruturas de dados, construção e consulta termo a termo com acumuladores;
  - tabela com as estatísticas exigidas;
  - distribuição das posting lists (mediana 1; 57,9% dos termos em um só documento; a maior lista, `studi`, com 2.358 documentos);
  - evidência de que a consulta não percorre a coleção: 558 postings visitados por consulta em média, 0,16% do índice;
  - consultas do test com ranking lexical menor que 100 documentos (134) ou vazio (16).
- Medições auxiliares feitas com um script no scratchpad (sem alterar o repositório): pré-processamento 5,51 s contra 0,27 s de inserção no índice; postings visitados e documentos com score por consulta.
- `docs/TP2_CHECKLIST.md`: seção 2 marcada como concluída, exceto a preparação para a defesa.
- Nenhum código foi alterado.

---

## 24/11/2026 — Grafo de conhecimento do projeto (graphify)

- Novo `.graphifyignore` na raiz, excluindo `*.png` (os gráficos do TP1 em `plots/` e `report-tp1/plots/`), para o grafo cobrir só código, docs e PDFs.
- Nova pasta `graphify-out/` com o grafo gerado (`graph.html`, `graph.json`, `GRAPH_REPORT.md`, `manifest.json`, `cost.json`, cache). Ela é regenerável e não está no `.gitignore`: decidir se será versionada ou ignorada.
- Concluído em 25/11/2026 (a montagem do grafo tinha sido interrompida em 24/11):
  - 643 nós, 1.398 arestas e 28 comunidades;
  - 65 arquivos: 55 de código, 7 docs e 3 PDFs;
  - extração semântica: ~162 mil tokens.
- Aviso de integridade do graphify: 271 arestas com uma ponta fora do grafo (`dangling`) e 51 arestas que se sobrepuseram a outra entre o mesmo par de nós (`collapsed`).
- `docs/TP2_CHECKLIST.md` e `docs/changes.md` foram editados depois da extração e ficaram marcados para reextração no próximo `graphify --update`.
- Nenhum arquivo de código, configuração ou relatório foi alterado.

---

## 24/11/2026 — BM25 sem percorrer a coleção a cada consulta

**Problema:** o `ProbabilisticModel.execute_query` copiava os dicionários inteiros de DF e de tamanhos dos documentos (`get_all_document_frequencies()` e `get_all_document_lengths()`) e calculava `avgdl = sum(document_lengths.values()) / N` em toda consulta. Isso percorria os 3.633 documentos a cada busca, contrariando o requisito 2 do enunciado ("não será permitido percorrer integralmente todos os documentos da coleção a cada consulta").

**Alterações:**
- `src/posting_list.py`
  - novo atributo `total_length`, somado em `_add_posting` durante a indexação (soma dos tamanhos de todos os documentos);
  - novos métodos `get_document_count()` e `get_average_document_length()`, ambos O(1).
- `src/probabilistic_model.py`
  - `execute_query` reescrito para calcular o BM25 termo a termo: para cada termo da consulta presente no vocabulário, calcula o IDF e percorre só a posting list desse termo, acumulando o score de cada documento;
  - `N` e `avgdl` vêm da posting list em O(1); DF e tamanhos são lidos direto dos dicionários, sem cópia;
  - removidos os vetores `numpy` intermediários e os imports não usados (`sqrt`, `numpy`).
  - A fórmula, a ordem das somas e o critério de ordenação são os mesmos, então os resultados não mudam.
- Testes novos:
  - `src/posting_list_test.py`: `test_posting_list_global_statistics` e `test_posting_list_average_length_of_empty_index`;
  - `src/lexical_index_test.py`: `test_bm25_score_matches_formula` (score conferido com a fórmula do BM25 calculada à mão) e `test_bm25_query_does_not_copy_collection_statistics` (falha se a consulta chamar `get_all_document_lengths()` ou `get_all_document_frequencies()`).

**Verificação:**
- Comparação da versão antiga com a nova em todas as consultas de dev (324) e test (323), com (k1, b) = (2,0; 0), (1,2; 0,75) e (0,5; 1,0): **rankings idênticos e diferença máxima de score igual a 0**.
- Tempo médio por consulta: de ~3,3 ms para ~0,9 ms.
- `uv run pytest -q src`: 76 testes passando.

**Pendência:** os rankings e métricas em `result/tp2/` continuam válidos, mas o tempo médio por consulta do lexical em `lexical_stats.json` é da versão antiga. Reexecutar `run_retrieval_pipeline.py --split test` para atualizá-lo.

---

## 24/11/2026 — Parâmetros do BM25: mantido k1 = 2,0 e b = 0

- `config/tp2_experiment.json`: `bm25_b` foi alterado para `0.75` e depois **revertido para `0.0`**. O valor final é igual ao original, escolhido no dev pelo maior NDCG@10 médio.
- `report-tp2/chapters/methodology/lexical.typ`: nova subseção "Escolha dos parâmetros k1 e b", com a tabela da grade no dev e a justificativa de b = 0 com dados do dev (documentos de tamanho homogêneo; relevância independente do tamanho).

---

## 24/11/2026 — Relatório do TP2

- Criada a pasta `report-tp2/`, com o mesmo template Typst do TP1 (`quill-assignment`):
  - `main.typ` com as seções a–g do enunciado, idioma pt-BR e cabeçalho com autores, Nº USP e filiação. Os emails ainda são o placeholder `<email>`;
  - um arquivo por subseção em `chapters/methodology/` e `chapters/results/`. As ainda não escritas contêm só um `// TODO`.
- Escrita a seção de pré-processamento (`chapters/methodology/preprocessing.typ`), com a tabela dos 4 pipelines (vocabulário, postings, tamanho médio e NDCG@10 no dev).
- Para os números do relatório, `tune_lexical.py` foi reexecutado no dev **sem** `--update-config`. Ele gerou `result/tp2/lexical_tuning_dev.csv` e chegou à mesma escolha do config.

---

## 24/11/2026 — Validação do dataset (etapa 1 do roadmap)

- Novo `docs/dataset_validation.md`, com a saída do `validate_experiment.py` (contagens por split, amostra do RAG, conferência das métricas com o `ir_measures`) e a verificação do uso dos splits no código.

---

## 24/11/2026 — Download alternativo do NFCorpus pelo Hugging Face

**Problema:** o servidor oficial do BEIR (`public.ukp.informatik.tu-darmstadt.de`) estava inacessível (timeout), e o `validate_experiment.py` falhava ao baixar o dataset.

**Alterações:**
- `src/nfcorpus_loader.py`:
  - o download pela UKP agora tem timeout de 30 s e grava num arquivo `.part` até terminar;
  - se esse download falhar, a nova função `download_nfcorpus_from_huggingface` baixa a cópia do BEIR no Hugging Face (`BeIR/nfcorpus` em parquet e `BeIR/nfcorpus-qrels` em TSV, com revisões fixadas) e converte para o layout padrão (`corpus.jsonl`, `queries.jsonl`, `qrels/{train,dev,test}.tsv`);
  - a origem usada é gravada em `data/nfcorpus/SOURCE.txt`.
- `pyproject.toml` e `uv.lock`: adicionada a dependência `pyarrow`, necessária para o `pandas` ler parquet.
- `docs/experiment_protocol.md`: registrada a fonte alternativa.

**Verificação:** o `validate_experiment.py` passou: 3.633 documentos, 323 consultas no test, amostra do RAG idêntica à do enunciado e métricas iguais às do `ir_measures`.

---

## 24/11/2026 — Checklist do trabalho

- Criado o checklist do TP2 (depois movido para `docs/TP2_CHECKLIST.md`), com todos os requisitos do enunciado e do roadmap marcados como concluídos, pendentes ou parciais.
