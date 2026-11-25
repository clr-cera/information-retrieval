# TP2 — Checklist completo (SCC0282 Recuperação de Informação, 2º Sem/2026)

Checklist derivado do enunciado `docs/enunciado_tp2.pdf` (incluindo o roadmap da última página),
cruzado com o estado atual do repositório. Estrutura do repositório: ver o README.

Legenda:
- `[x]` concluído (implementado no código / registrado no repositório)
- `[ ]` pendente
- **⚠️ parcial** — existe algo, mas falta parte do que o enunciado exige (detalhado na própria linha)

> **Prazo oficial:** 26/11/2026 às 23:59 (divulgação 02/10/2026). Grupo: até 2 pessoas (mesma configuração do T1).
>
> **Observação geral (25/11/2026):** os resultados do TP2 estão em `result/tp2/`, regerados com a configuração final
> (BM25 k1 = 1,2 e b = 0,75; RRF k = 10; `ms-marco-MiniLM-L6-v2`). `result/` está no `.gitignore`: os CSVs precisam
> ser incluídos manualmente no arquivo entregue. Testes: `uv run pytest` (74 testes do TP2) e `uv run pytest tp1/src` (27 do TP1), todos passando.

---

## 0. Etapa 1 do roadmap — Dataset e splits ✅ concluída

- [x] Usar o NFCorpus na versão disponibilizada pelo BEIR — `src/ir/data.py`
  - [x] Fonte principal: `nfcorpus.zip` da UKP/TU Darmstadt (servidor inacessível em 24/11/2026)
  - [x] Alternativa automática: cópia do BEIR no Hugging Face (`BeIR/nfcorpus` + `BeIR/nfcorpus-qrels`, revisões fixadas); a origem usada fica em `data/nfcorpus/SOURCE.txt`
- [x] Usar os arquivos padronizados `corpus.jsonl`, `queries.jsonl` e `qrels/{train,dev,test}.tsv`
- [x] Download automático e extração para `data/nfcorpus` (sobrescrevível com `NFCORPUS_DIR`)
- [x] Consultas de cada split = apenas as que possuem julgamento no qrels do split (e não as 3.237 de `queries.jsonl`)
- [x] Test com 323 consultas, conferido por `src/scripts/validate_experiment.py`, que imprime as contagens por split
- [x] Representação do documento = `title + " " + text` em **todos** os sistemas (lexical, semântico e reranking) — `Document.searchable_text`
- [x] IDs mantidos como string
- [x] Protocolo documentado em `docs/experiment_protocol.md`
- [x] Configuração experimental congelada em `config/tp2_experiment.json`
- [x] Rodar `src/scripts/validate_experiment.py` e guardar a saída para citar no relatório — [dataset_validation.md](dataset_validation.md)
  - train: 3.633 docs / 2.590 consultas / 110.575 qrels; dev: 3.633 / 324 / 11.385; test: 3.633 / 323 / 12.334
  - Amostra do RAG idêntica à do enunciado; P@10, R@10, AP@10 e NDCG@10 iguais ao `ir_measures`

### Regras de uso dos splits (não violar)
- [x] Dev usado para ajustar: pré-processamento, k1/b do BM25, limiares de correção ortográfica, modelo de embeddings, k do RRF e modelo de reranking (scripts `tune_*.py`, todos com `--split dev` por padrão)
- [x] Test reservado para a avaliação final (`run_retrieval_pipeline.py --split test`, que só lê a configuração congelada)
- [x] Código auditado: os qrels do test **não** são usados para modificar consultas, escolher parâmetros, alterar rankings ou favorecer exemplos (ver a auditoria em [dataset_validation.md](dataset_validation.md))
  - Exceções permitidas pelo enunciado: escolha das consultas do experimento de erros (NDCG@10 original > 0, item 4.iii) e a amostra fixa do RAG (seed 42)
  - A declaração formal no relatório está listada na seção "Entrega › Relatório › d. Avaliação"

---

## 1. Pré-processamento (Requisito 1 / etapa 2 do roadmap)

- [x] Leitura dos textos — `src/ir/data.py`
- [x] Tokenização (split em espaços + remoção de caracteres não alfanuméricos) — `document_processor.tokenize`
- [x] Normalização (lowercase) — `document_processor.normalize`
- [x] Remoção de stopwords (NLTK, inglês) — `document_processor.remove_stopwords`
- [x] Stemming (Porter, NLTK) — `document_processor.stem`
- [x] Lematização (WordNet, NLTK) disponível — `document_processor.lemmatize` (não usada em nenhum pipeline)
- [x] 4 variantes de pipeline comparadas no dev (`tune_lexical.py`); selecionada: `WithStopRemovalWithStemming`
- [x] Mesmo pré-processamento aplicado a documentos e consultas (`get_index_terms_freq`)
- [x] **Relatório:** descrever as etapas usadas, as bibliotecas (NLTK 3.10.3) e as principais decisões para representar documentos e consultas — `docs/report/chapters/methodology/preprocessing.typ`
  - [x] Descrever o efeito da tokenização simples (hífens e barras unem termos: `meta-analysis` → `metaanalysis`, `follow-up` → `followup`, `and/or` → `andor`)
  - [ ] **⚠️ parcial — lematização:** o relatório informa que ela não entrou na grade do dev e por isso não é usada; falta uma justificativa de fato (custo da etiquetagem morfossintática) ou testá-la no dev
  - [x] Citar os resultados do dev que levaram à escolha do pipeline (`result/tp2/lexical_tuning_dev.csv`, regerado em 24/11/2026 e com a mesma escolha do config)
  - [x] Tabela com vocabulário, postings e tamanho médio dos documentos para os 4 pipelines
- [ ] **⚠️ Tokens vazios:** `tokenize` transforma pontuação isolada (por exemplo, " - ") em um token vazio `""`, que é indexado como termo (6.109 ocorrências em 1.513 documentos). Decidir se o código será corrigido (descartar tokens vazios) antes da execução final; se for, atualizar a tabela do relatório (há um `// TODO` no `preprocessing.typ`)

---

## 2. Índice invertido implementado do zero (Requisito 2 / etapa 3 do roadmap) ✅ concluído (exceto a preparação para a defesa)

- [x] Índice invertido próprio (`src/ir/lexical.py`): dicionário `termo → {doc_id: tf}`, sem bibliotecas prontas de indexação
- [x] Armazena TF por documento (postings), DF, frequência global do termo e tamanho dos documentos
- [x] Busca percorre apenas as posting lists dos termos da consulta (`ProbabilisticModel.execute_query`)
- [x] **Estatísticas globais em O(1) por consulta** (corrigido em 24/11/2026, ver [changes.md](changes.md)): a `PostingList` mantém `total_length` durante a indexação, e o BM25 obtém `N` e `avgdl` sem percorrer a coleção e lê DF e tamanhos direto dos dicionários, sem copiá-los. Cada consulta visita apenas as posting lists dos termos da consulta
  - Rankings e scores idênticos à versão anterior (diferença 0 nas 647 consultas de dev e test, para 3 combinações de k1 e b); tempo médio por consulta caiu de ~3,3 ms para ~0,9 ms
  - Testes novos: estatísticas globais da posting list, score conferido com a fórmula e garantia de que a consulta não chama `get_all_document_lengths()` nem `get_all_document_frequencies()`
- [x] Tempo médio por consulta atualizado em `result/tp2/lexical_stats.json` com a versão nova (25/11/2026: `run_lexical.py --split test` com `--rankings-output` e `--metrics-output` apontando para fora de `result/tp2/`, para não sobrescrever o `metrics_per_query.csv` combinado; ranking e métricas idênticos aos anteriores)
  - ⚠️ Rodar `run_lexical.py` **sem** esses dois argumentos sobrescreve o `metrics_per_query.csv` só com o modelo lexical
- [x] Registro do número de termos do vocabulário — `IndexStats.vocabulary_size`
- [x] Registro do número total de postings — `IndexStats.posting_count`
- [x] Registro do tempo de construção do índice — `IndexStats.build_time_seconds`
- [x] Registro do tempo médio de processamento das consultas — `LexicalRun.average_query_time_seconds` (salvo em `lexical_stats.json`)
- [x] Gerar `result/tp2/lexical_stats.json` no test e reportar os quatro números no relatório: vocabulário 28.942 termos, 350.458 postings, construção em 7,32 s e 0,90 ms por consulta na execução final de 25/11/2026 (k1 = 1,2; b = 0,75) (AMD Ryzen 7 5700U, 14 GB de RAM)
- [x] **Relatório:** estruturas de dados, construção, processamento da consulta (termo a termo com acumuladores), estatísticas e evidência de que a consulta não percorre a coleção — `docs/report/chapters/methodology/inverted_index.typ`
  - Evidência: em média 558 postings visitados por consulta (0,16% do índice) e 485 documentos com score (13,3% da coleção)
  - Achado registrado no relatório: 134 das 323 consultas do test recuperam menos de 100 documentos no lexical e 16 não recuperam nenhum. Retomar isso na análise da busca híbrida
  - O termo vazio `""` (ver seção 1) tem a 5ª maior posting list (1.513 documentos) e entra na contagem do vocabulário; há um `// TODO` no `inverted_index.typ` para atualizar os números se o código for corrigido
- [ ] **Defesa:** todos os integrantes devem saber mostrar como o índice é construído e consultado
 
---

## 3. Busca lexical — baseline (Requisito 3 / etapa 4 do roadmap) ✅ concluído

- [x] Uma única alternativa escolhida: **BM25** (`src/ir/lexical.py`, reaproveitado do TP1)
- [x] BM25 usa o índice invertido próprio
- [x] k1 e b avaliados **no dev** (grade k1 ∈ {0,5; 1,2; 2,0} × b ∈ {0; 0,75; 1,0}) — adotados os **valores usuais k1 = 1,2 e b = 0,75** (NDCG@10 dev = 0,2906), decidido em 25/11/2026
  - O maior valor da grade foi k1 = 2,0 / b = 0 (0,2916), só 0,001 acima; toda a grade fica entre 0,2854 e 0,2916
  - Por que b tem efeito pequeno no NFCorpus (dados do dev): documentos de tamanho homogêneo (média de 155 termos, CV de 0,37, 80% entre 87 e 212 termos) e relevância independente do tamanho (relevantes com média de 156,2 termos; 84% a 87% de documentos relevantes em todos os quartis)
  - `config/tp2_experiment.json` editado à mão (`bm25_k1: 1.2`, `bm25_b: 0.75`). **Não** rodar `tune_lexical.py --update-config`, que voltaria para o maior valor da grade (2,0/0)
- [x] O mesmo modelo lexical é usado nos experimentos seguintes (erros, híbrido, reranking, RAG) via `config/tp2_experiment.json`
- [x] Tempo médio das consultas medido
- [ ] (Opcional — não implementado, mas discutido no relatório) Desempate explícito na ordenação do BM25. Hoje o empate segue a ordem das posting lists (ordem do `corpus.jsonl`): é determinístico, mas arbitrário
  - **Empates (motivo da troca para os valores usuais):** com b = 0, 93 das 324 consultas do dev (107 das 323 do test) têm empate entre a 10ª e a 11ª posição, e só a ordem de desempate faz o NDCG@10 do dev variar de 0,2850 a 0,3021. Com b = 0,75, só 3 consultas do dev têm esse empate, e a variação cai para 0,2899–0,2915. Está no relatório (subseção "Empates de score")
- [x] **Relatório:** escolha do BM25 justificada (`docs/report/chapters/methodology/lexical.typ`) com o resultado do TP1 (BM25 superior no Cranfield), a comparação no dev do NFCorpus com os parâmetros adotados (BM25 0,2906 × TF-IDF com cosseno 0,2880; o TF-IDF vence mais consultas, 86 × 82, mas o BM25 vence por margens maiores) e os parâmetros de saturação e de tamanho
  - [x] Fórmula do BM25 e do IDF, e como o score usa o índice
- [x] **Relatório:** justificar os valores usuais k1 = 1,2 e b = 0,75 com os números do dev (tabela da grade, efeito pequeno dos parâmetros, empates com b = 0, homogeneidade de tamanho) — `docs/report/chapters/methodology/lexical.typ`

---

## 4. Tolerância a erros — correção ortográfica (Requisito 4 / etapa 5 do roadmap) ✅ concluído (o item opcional não foi feito)

### Implementação
- [x] Geração de candidatos por k-gramas (com marcadores `^`/`$`) e índice de k-gramas — `SpellingCorrector` em `src/ir/lexical.py`
- [x] Filtragem por coeficiente de Jaccard
- [x] Seleção por distância de edição (Levenshtein implementado)
- [x] Desempate por Jaccard e depois por frequência na coleção
- [x] Só corrige termos desconhecidos (fora do dicionário)
- [x] Limiares ajustados no dev (`tune_typo.py`: k ∈ {2,3}, Jaccard ∈ {0,2…0,5}, distância ∈ {1,2,3}; 200 erros simulados no dev) — selecionado k = 2, Jaccard = 0,2, distância máx. = 2, com 92,0% de correções exatas (`result/tp2/typo_tuning_dev.csv`, regerado em 25/11/2026)

### Padronização exigida
- [x] (i) Dicionário formado pelos termos da coleção **antes** do stemming/lematização (`build_dictionary` = tokenize + lowercase)
- [x] (ii) Cada erro gera termo **inexistente** no dicionário (`inject_error` filtra variantes que estão no vocabulário)
- [x] (iii) Só consultas do test com NDCG@10 original > 0
- [x] (iv) Avaliação no sistema **lexical** com NDCG@10
- [x] (iv) Recuperação por consulta = (NDCG corrigida − NDCG erro) / (NDCG original − NDCG erro) quando o denominador > 0; caso contrário, registra que o erro não reduziu o desempenho (`erro_reduziu_desempenho`)

### Experimento
- [x] 10 consultas do conjunto **test** (`run_typo.py --split test --queries 10`)
- [x] Tipos de erro variados: inserção, remoção, substituição e transposição (rotação entre os 4 tipos)
- [x] Três condições por consulta: original × com erro × corrigida
- [x] Saída em `typo_experiment.csv` + resumo `typo_experiment_summary.json` (média de recuperação, correções exatas)
- [x] Experimento separado: os demais experimentos usam as consultas originais, sem correção
- [x] Executado no test (25/11/2026, BM25 k1 = 1,2 e b = 0,75) e conferido por `src/scripts/analyze_typo.py`: 10 consultas; tipos 3 inserções, 3 remoções, 2 substituições, 2 trocas; cada consulta com exatamente um termo alterado, fora do dicionário; termo original no dicionário. Saída em `result/tp2/typo_analysis.md`
- [x] Seleção automática e reprodutível (seed 42) documentada no relatório: as 10 primeiras consultas do test em ordem de ID com NDCG@10 > 0; erro no termo mais longo (não stopword, ≥ 4 letras); tipo alternado por consulta. O relatório discute o viés de atingir o termo mais específico
- [x] Nenhuma correção indevida: nas 10 consultas, a consulta corrigida é idêntica à original normalizada (`analyze_typo.py` confere que nenhum outro termo foi alterado)
- [ ] (Opcional — não feito, mas citado no relatório) Aplicar as mesmas consultas com erro ao sistema **semântico** e discutir a robustez dos embeddings a erros ortográficos
- [x] **Relatório:** metodologia (`docs/report/chapters/methodology/typo_tolerance.typ`: dicionário, algoritmo, ajuste no dev, protocolo) e resultados (`docs/report/chapters/results/typo_tolerance.typ`: tabela por consulta, médias 0,4706 → 0,1625 → 0,4706, recuperação de 100% nas 8 consultas afetadas, impacto do erro e os 2 casos em que o erro melhorou o NDCG@10, explicados com dados)

---

## 5. Recuperação semântica (Requisito 5 / etapa 6 do roadmap) ✅ concluído

- [x] Bi-encoder pré-treinado via Sentence Transformers — `src/ir/neural.py`
- [x] Embeddings dos documentos calculados previamente e salvos (`data/embeddings/<modelo>/document_embeddings.npy` + metadados)
- [x] Embedding da consulta gerado a cada busca e similaridade calculada com todos os documentos (busca exaustiva, permitida)
- [x] Modelo escolhido no dev entre `all-MiniLM-L6-v2` (NDCG@10 0,3024) e `multi-qa-MiniLM-L6-cos-v1` (0,2718) com `tune_semantic.py` (reexecutado em 25/11/2026, sem `--update-config`; `result/tp2/semantic_tuning_dev.csv`) — selecionado `sentence-transformers/all-MiniLM-L6-v2`
- [x] Normalização L2 dos embeddings + produto escalar (= cosseno)
- [x] Registro da dimensionalidade, do `max_seq_length`, do nº de documentos truncados, do tempo de geração dos embeddings, do tempo médio por consulta e do dispositivo (`semantic_stats.json`)
- [x] Versão do modelo registrada no relatório: revisão `1110a243fdf4706b3f48f1d95db1a4f5529b4d41` do Hugging Face, Sentence Transformers 6.3.0, PyTorch 2.15.0, Transformers 5.23.0. O código continua registrando só o nome do modelo (não foi alterado)
- [x] Tempo de geração dos embeddings medido em execução isolada: 109,7 s (30 ms por documento), CPU AMD Ryzen 7 5700U com 8 threads. O valor no cache (154 s) estava inflado por concorrência com outros processos; os vetores recalculados são idênticos aos do cache
- [x] `semantic_stats.json` gerado no test (25/11/2026) e tudo reportado no relatório (`docs/report/chapters/methodology/semantic.typ`): nome e versão, biblioteca, arquitetura (mean pooling), dimensão 384, cosseno via produto escalar, normalização L2, 109,7 s para os embeddings, 0,16 s por consulta, máximo de 256 tokens e truncamento de 2.864 dos 3.633 documentos (78,8%; 32,2% dos tokens descartados; média de 357 tokens por documento)

---

## 6. Avaliação da recuperação (Requisito 6 / etapa 7 do roadmap) ✅ concluído

- [x] Lexical e semântico avaliados sobre as **mesmas** consultas do test
- [x] Precision@10, Recall@10, MAP@10 e NDCG@10 implementados — `src/ir/metrics.py`
- [x] P@10/R@10/AP@10: relevante = grau > 0
- [x] NDCG@10 com graus preservados, ganho linear e ranking ideal a partir de **todos** os julgamentos da consulta
- [x] AP@10 truncada em 10, dividida pelo total de relevantes nos qrels (convenção trec_eval/ir_measures); MAP@10 = média
- [x] Recall@10 com denominador = total de relevantes nos qrels
- [x] Conferência com `ir_measures` (`validate_experiment.py` + `src/tests/test_metrics.py`)
- [x] Métricas preservadas por consulta (`metrics_per_query.csv`)
- [x] Conferência com o `ir_measures` citada no relatório. Além da validação em rankings sintéticos, os rankings finais dos 4 sistemas (`results_*.csv`) foram reavaliados com o `ir_measures`, consulta a consulta: diferença máxima de 3×10⁻¹⁶ em relação ao `metrics_per_query.csv`. A média de AP10 coincide com o MAP@10 do `retrieval_summary.json`, a coluna `relevance` confere com os qrels, e há 323 consultas por sistema (25/11/2026)
- [x] **Relatório:** tabela de médias globais Lexical × Semântico no test (`docs/report/chapters/results/lexical_vs_semantic.typ`), com a comparação por consulta: semântico melhor em 109, lexical em 106, empate em 108 (77 com NDCG@10 zero nos dois); NDCG@10 zero em 102 consultas (lexical) e 100 (semântico)

---

## 7. Comparação lexical × semântica por consulta (Requisito 7 / etapa 8 do roadmap)

- [ ] Script para calcular ΔNDCG@10 = semântico − lexical por consulta (a partir de `metrics_per_query.csv`)
- [ ] Identificar as **3 consultas com maior vantagem do semântico**
- [ ] Identificar as **3 consultas com maior vantagem do lexical**
- [ ] Para cada uma das 6 consultas, apresentar:
  - [ ] texto da consulta
  - [ ] Top-5 de cada método (lexical e semântico)
  - [ ] indicação de quais documentos são relevantes (e o grau)
  - [ ] scores BM25 e similaridades de cosseno
  - [ ] análise das razões da diferença
- [ ] Na discussão, buscar evidências de: correspondência lexical, termos técnicos, sinonímia, paráfrase, variação de vocabulário e ambiguidade
- [ ] Sustentar toda afirmação com valores observados nos dados (por exemplo tf do termo no documento, df, tamanho do documento, posição), e nunca afirmar "o documento era longo" ou "o termo era mais frequente" sem mostrar o número
- [ ] Não comparar diretamente scores BM25 com cossenos sem justificativa/normalização
- [ ] (Sugestão) Script `analyze_lexical_vs_semantic.py` que gere uma tabela/Markdown com esses dados, para reprodutibilidade

---

## 8. Busca híbrida — RRF (Requisito 8 / etapa 9 do roadmap)

- [x] RRF implementado: `RRF(d) = Σ 1/(k + rank_s(d))`, rank começando em 1 — `src/ir/neural.py`
- [x] Documentos ausentes de um ranking não recebem contribuição desse sistema
- [x] Fusão dos **100 primeiros** de cada sistema (`FUSION_DEPTH = 100`)
- [x] k ajustado no dev com k ∈ {10, 60, 100}, critério: maior NDCG@10 médio — selecionado **k = 10** (`tune_hybrid.py`, `hybrid_tuning_dev.csv`)
- [x] Valor selecionado mantido na avaliação final no test
- [x] Avaliação Lexical × Semântico × Híbrido com P@10, R@10, MAP@10 e NDCG@10 (`run_retrieval_pipeline.py`)
- [ ] Medir o tempo da etapa de fusão (hoje não é registrado; necessário para a tabela de tempos)
- [ ] **Relatório:** tabela do ajuste de k no dev, tabela comparativa no test, explicar por que o RRF evita comparar scores de escalas diferentes
- [ ] **Defesa:** saber calcular o RRF de um documento à mão a partir dos CSVs

---

## 9. Reranking (Requisito 9 / etapa 10 do roadmap)

- [x] Híbrido usado como recuperador inicial
- [x] Top-50 do híbrido reordenados por cross-encoder — `src/ir/neural.py` (`RERANK_DEPTH = 50`)
- [x] Documentos abaixo da posição 50 mantêm a ordem relativa do híbrido (ranking completo preservado)
- [x] Modelo escolhido no dev entre `ms-marco-MiniLM-L6-v2` e `ms-marco-TinyBERT-L2-v2` (`tune_reranker.py`) — selecionado `cross-encoder/ms-marco-MiniLM-L6-v2`
- [x] Comparação Lexical × Semântico × Híbrido × Híbrido + reranking com as 4 métricas
- [x] Tempo médio do reranking por consulta registrado (`reranking_stats.json`)
- [x] Comprimento máximo de entrada do cross-encoder e nº de pares truncados registrados
- [ ] Gerar `reranking_stats.json` no test
- [ ] Tabela com o **tempo médio de todas as etapas** (lexical, semântica, fusão, reranking, e no RAG a geração), incluindo o hardware
- [ ] Atenção: em `results_reranking.csv` a coluna `score` mistura scores do cross-encoder (top-50) com scores RRF (posições 51–100). Documentar isso no relatório/README
- [ ] Registrar a versão do modelo de reranking
- [ ] **Relatório:** informar e **justificar** a escolha do modelo de reranking (dev + custo); informar o comprimento máximo e o truncamento

---

## 10. Análise do reranking (Requisito 10 / etapa 11 do roadmap)

- [ ] Script para comparar NDCG@10 híbrido × reranking por consulta
- [ ] Identificar os **2 casos com maior ganho** de NDCG@10 após o reranking
- [ ] Identificar **1 caso com pouca ou nenhuma alteração**
- [ ] Identificar **1 caso em que o reranking piorou** o NDCG@10
- [ ] Para cada caso: mostrar os principais documentos que mudaram de posição (posição antes → depois, relevância, score do cross-encoder)
- [ ] Discutir a provável razão de cada alteração, com evidências dos dados (trecho do documento, truncamento, correspondência com a consulta etc.)
- [ ] **Defesa:** saber justificar a alteração de posições após o reranking

---

## 11. Retrieval-Augmented Generation (Requisito 11 / etapa 12 do roadmap)

- [ ] Escolher a LLM (aberta local/Colab, como Qwen, Llama, Gemma ou Mistral, ou comercial via API). `llm` está `null` no config
- [ ] Implementar o pipeline: consulta → recuperação híbrida → reranking → seleção de contexto → LLM → resposta
- [ ] Cada item do `corpus.jsonl` = uma unidade de contexto (sem chunking obrigatório)
- [ ] (Opcional) Chunking adicional preservando o `doc_id` original
- [ ] Seleção de contexto: Top-5 após o reranking, com os respectivos `doc_id`
- [ ] Parâmetros fixos: temperatura 0 (ou a mínima), seed fixa quando disponível, `max_tokens` definido
- [ ] Preencher no `config/tp2_experiment.json`: `llm`, `llm_temperature`, `llm_max_tokens`, `rag_language`
- [ ] Credenciais/chaves de API via variável de ambiente, **nunca** commitadas nem incluídas na entrega
- [ ] **Relatório:** modelo e versão, forma de execução (local ou serviço externo), temperatura, nº máximo de tokens, demais parâmetros relevantes, custo aproximado (se pago) e hardware (se local)

---

## 12. Experimento sem RAG × com RAG (Requisito 12 / etapa 13 do roadmap)

- [x] As 10 consultas fixas foram reproduzidas com o código do enunciado (seed 42, consultas do test terminadas em "?") — `select_rag_query_ids` + checagem em `validate_experiment.py`
- [x] Lista conferida: PLAIN-68, PLAIN-2450, PLAIN-153, PLAIN-2850, PLAIN-2750, PLAIN-270, PLAIN-2470, PLAIN-2430, PLAIN-238, PLAIN-3342
- [ ] Condição **A (sem RAG):** LLM recebe só a pergunta, sem acesso ao NFCorpus
- [ ] Condição **B (com RAG):** LLM recebe a pergunta + Top-5 documentos após o reranking, com seus identificadores
- [ ] Prompt do RAG instruindo a: responder com base no contexto fornecido, **indicar as fontes** (doc_ids) e **informar quando não houver evidência suficiente**
- [ ] Mesma LLM e mesmos parâmetros nas duas condições
- [ ] Respostas no **mesmo idioma** nas duas condições; idioma informado no relatório
- [ ] Salvar prompt completo, contexto (doc_ids) e resposta de cada uma das 20 execuções
- [ ] Script reprodutível (por exemplo `run_rag.py`) que gere o `rag_experiment.csv` (o writer `write_rag_experiment_csv` já existe)

---

## 13. Avaliação do RAG (Requisito 13 / etapa 14 do roadmap)

### Recuperação (para as 10 consultas)
- [x] Hit@k implementado (`metrics.hit_at_k`)
- [ ] Calcular **Recall@5**, **Precision@5** e **Hit@5** (1 se ao menos um relevante foi enviado à LLM) sobre o Top-5 enviado
- [ ] Comentar que Recall@5 baixo é esperado (média de cerca de 38 relevantes por consulta)

### Geração (avaliação humana estruturada, notas 0/1/2 com justificativa)
- [ ] **Fidelidade** — 0: afirmações importantes não sustentadas ou contraditórias / 1: parcialmente sustentada / 2: afirmações principais sustentadas pelo contexto
- [ ] **Completude** — 0: não responde aos aspectos principais / 1: responde parcialmente / 2: cobre adequadamente o que pode ser respondido
- [ ] **Utilidade** — 0: não atende à necessidade / 1: parcialmente útil / 2: responde diretamente à necessidade
- [ ] **Rastreabilidade** — 0: não é possível identificar fontes / 1: só parte das afirmações associável às fontes / 2: afirmações principais associáveis aos doc_ids
- [ ] Breve justificativa para **cada** nota
- [ ] (Recomendado) Avaliar às cegas: embaralhar as respostas A/B antes de pontuar
- [ ] (Recomendado) Dois integrantes avaliam de forma independente e reportam a concordância (por exemplo % de concordância e/ou kappa)
- [ ] Condição A: registrar explicitamente que não há contexto externo
- [ ] Condição A: avaliar a **Fidelidade** comparando com os **mesmos Top-5** usados na condição B daquela consulta
- [ ] Condição A: **Rastreabilidade = "N/A"**, excluída da média; discutir qualitativamente a ausência de fontes e o impacto na verificabilidade
- [ ] Apresentar e discutir as médias por critério nas duas condições
- [ ] Discussão focada no efeito da recuperação sobre qualidade, fidelidade e disponibilidade de evidências (não é obrigatório mostrar que o RAG é sempre melhor)

---

## 14. Análise de falhas ponta a ponta (Requisito 14 / etapa 15 do roadmap)

Escolher entre as 10 consultas do experimento:
- [ ] 1 consulta em que o RAG **melhorou claramente** a resposta
- [ ] 1 consulta com **pouca diferença**
- [ ] 1 consulta em que o RAG **não ajudou ou prejudicou**
- [ ] No último caso, localizar o estágio do problema: recuperação lexical, recuperação semântica, fusão, reranking, seleção de contexto ou geração
  - [ ] Verificar se a informação necessária **chegou ou não** ao contexto (posição dos relevantes no lexical, no semântico, no híbrido e no rerank, e o que entrou no Top-5)
  - [ ] Não basta dizer "a LLM errou"
- [ ] Análise detalhada de cada um dos 3 casos, com evidências (doc_ids, posições, trechos)

---

## 15. Arquivos padronizados de resultados (Requisito 15 / etapa 16 do roadmap)

Writers implementados em `src/ir/data.py`; caminhos definidos em `experiment_config.py` (`result/tp2/`).

| Arquivo | Writer/esquema | Gerado e incluído na entrega |
|---|---|---|
| `results_lexical.csv` | [x] `query_id, doc_id, rank, score, relevance`, top-100 | [ ] |
| `results_semantic.csv` | [x] idem | [ ] |
| `results_hybrid.csv` | [x] idem | [ ] |
| `results_reranking.csv` | [x] idem | [ ] |
| `metrics_per_query.csv` | [x] `query_id, model, P10, R10, AP10, NDCG10` (4 modelos) | [ ] |
| `typo_experiment.csv` | [x] `query_id, query_original, query_erro, query_corrigida, tipo_erro, NDCG10_original, NDCG10_erro, NDCG10_corrigida` (+ `recuperacao`, `erro_reduziu_desempenho`) | [ ] |
| `rag_experiment.csv` | [x] `query_id, query, condition (A/B), context_doc_ids, prompt, answer`, 4 notas + 4 justificativas | [ ] (sem pipeline RAG ainda) |

- [ ] Executar `run_retrieval_pipeline.py --split test` para gerar os 4 rankings + `metrics_per_query.csv`
- [ ] Conferir: 100 documentos por consulta (ou todos, se o BM25 recuperar menos de 100), 323 consultas
- [ ] Conferir: média de `AP10` em `metrics_per_query.csv` = MAP@10 reportado no relatório (por modelo)
- [ ] Executar `run_typo.py` e gerar `typo_experiment.csv`
- [ ] Gerar `rag_experiment.csv` com as 20 linhas (10 consultas × A/B), notas e justificativas
- [ ] **`result/` está no `.gitignore`**: garantir que os CSVs finais entrem no arquivo entregue no Moodle (copiar para uma pasta versionada ou incluir manualmente no .zip)
- [ ] Os resultados não podem existir apenas como saída de notebook

---

## Análise crítica (transversal)

- [ ] Não se limitar a tabelas de médias: investigar exemplos concretos e relacioná-los aos conceitos da disciplina
- [ ] Usar as análises por consulta para explicar **por que** os comportamentos ocorreram
- [ ] Cada comparação deve alterar **apenas** o componente investigado
- [ ] Não comparar scores de modelos diferentes sem justificativa ou normalização
- [ ] Afirmações sobre frequência de termos, tamanho de documentos, posição no ranking, similaridade ou custo acompanhadas de evidência dos próprios experimentos

---

## Entrega (etapa 16 do roadmap)

### 1. Código-fonte completo
- [x] Módulos de dataset, índice, BM25, correção ortográfica, semântico, RRF, reranking, métricas e writers
- [x] Testes unitários (`src/*_test.py`)
- [ ] Módulo/script de RAG
- [ ] Scripts de análise (lexical × semântico, reranking, RAG/falhas)
- [x] Código do TP1 isolado em `tp1/` (25/11/2026): `tp1/src/` (main.py com Cranfield, experiments.py, get_discrepant_queries.py, plots.py, vectorial_model.py e cópias dos módulos compartilhados), `tp1/analysis.py`, `tp1/plots/`, `tp1/report/`, `tp1/web_backend/` e `tp1/web_ui/`. Os 27 testes do TP1 continuam passando
- [ ] **Não** incluir arquivos grandes regeneráveis (dataset, embeddings, modelos, índice serializado, `.venv`); o README deve dizer como gerá-los
- [ ] Entregar o código no **Moodle** (link de repositório não substitui)

### 2. README (o atual ainda é do TP1, com Cranfield)
- [x] Integrantes com nome completo e Nº USP (Clara Ernesto de Carvalho - 14559479; Ariel Alves da Silva - 8847378)
- [ ] Instruções de instalação (uv/pip, incluindo `torch`, `sentence-transformers`, `ir-measures` e o pacote da LLM)
- [ ] Instruções de execução e **ordem recomendada** dos scripts, por exemplo:
  1. `validate_experiment.py`
  2. `tune_lexical.py --update-config`
  3. `tune_typo.py --update-config`
  4. `tune_semantic.py --update-config`
  5. `tune_hybrid.py --update-config`
  6. `tune_reranker.py --update-config`
  7. `run_retrieval_pipeline.py --split test`
  8. `run_typo.py`
  9. script do RAG
  10. scripts de análise
- [ ] Versão da linguagem (Python 3.13)
- [ ] Bibliotecas e versões principais (atualizar; a lista atual é do TP1)
- [ ] Modelo lexical escolhido (BM25, k1 = 1,2, b = 0,75, pipeline)
- [ ] Modelo de embeddings
- [ ] Modelo de reranking
- [ ] LLM utilizada
- [ ] Hardware empregado
- [ ] Como gerar dataset/embeddings (download automático, `NFCORPUS_DIR`)
- [ ] Como configurar a chave de API (se houver), sem incluí-la

### 3. Resultados completos
- [ ] Todos os CSVs padronizados incluídos no arquivo entregue (ver seção 15)
- [ ] Nenhuma chave de API, senha ou credencial na entrega

### 4. Relatório em PDF (até 20 páginas, PT ou EN; o limite exclui só as referências; anexos não podem ser usados para contornar o limite)
O relatório do TP2 fica em `docs/report/` (Typst, mesmo template do TP1: `quill-assignment`). Compilar com `typst compile docs/report/main.typ`.
- [x] Estrutura criada: `main.typ` com as seções a–g e um arquivo por subseção em `chapters/`. Títulos numerados (1, 1.1, 1.1.1), sumário com dois níveis, e todas as subseções exigidas visíveis no sumário. As ainda não escritas mostram "Seção em elaboração." e um `// TODO` com o que deve entrar (remover antes da entrega)
- [ ] **⚠️ parcial — a. Cabeçalho:** capa em português com título, autores (nome completo e Nº USP), professor, filiação (ICMC/USP) e data; **faltam os emails** (placeholder na linha "Emails:" do `main.typ`)
- [ ] **b. Introdução:** contextualização, motivação e objetivo
- [ ] **c. Metodologia:**
  - [x] pré-processamento — `chapters/methodology/preprocessing.typ`
  - [x] índice invertido — `chapters/methodology/inverted_index.typ`
  - [x] busca lexical — `chapters/methodology/lexical.typ` (escolha do modelo, fórmula, parâmetros e empates)
  - [x] tolerância a erros — `chapters/methodology/typo_tolerance.typ`
  - [x] recuperação semântica — `chapters/methodology/semantic.typ`
  - [ ] busca híbrida
  - [ ] reranking
  - [ ] RAG
- [x] **d. Avaliação:** — `docs/report/chapters/evaluation.typ`
  - [x] dataset
  - [x] splits
  - [x] qrels
  - [x] métricas (definições exatas de P@10, R@10, AP@10/MAP@10, NDCG@10; P@5, R@5 e Hit@5 citadas para o RAG; conferência com o ir_measures)
  - [x] modelos (tabela da configuração final; LLM ainda "a definir")
  - [x] parâmetros
  - [x] ambiente computacional
  - [x] protocolo experimental (o que foi ajustado no dev e o que foi avaliado no test), declarando que os qrels do test não foram usados para ajustes e citando as duas exceções permitidas e a origem dos dados (cópia do BEIR no Hugging Face, ver [dataset_validation.md](dataset_validation.md))
- [ ] **e. Resultados obtidos e análise:**
  - [ ] **⚠️ parcial — lexical × semântico:** resultados globais e comparação por consulta escritos; falta a análise das 6 consultas (requisito 7)
  - [x] tolerância a erros — `chapters/results/typo_tolerance.typ`
  - [ ] híbrido
  - [ ] reranking (global + 4 casos)
  - [ ] tempos (índice, consultas, embeddings, fusão, reranking, geração)
  - [ ] RAG (recuperação + avaliação humana)
  - [ ] análise de falhas (3 casos)
- [ ] **f. Considerações finais:** principais conclusões tiradas dos experimentos
- [ ] **g. Uso de ferramentas de IA:** atividades em que IA generativa foi usada como apoio (programação, depuração, explicação, revisão), sem histórico completo. Separar do uso de IA como componente do experimento (embeddings, cross-encoder, LLM), que vai na metodologia
- [ ] Referências bibliográficas (Manning et al. 2008, BEIR, NFCorpus, Sentence Transformers, ir_measures, modelos usados)
- [ ] Conferir o limite de 20 páginas

---

## Defesa individual (preparação de ambos os integrantes)

Qualquer integrante pode ser solicitado a:
- [ ] Explicar qualquer parte do código
- [ ] Mostrar como o índice invertido foi construído
- [ ] Explicar um cálculo do RRF
- [ ] Interpretar um resultado por consulta
- [ ] Justificar a alteração de posições após o reranking
- [ ] Mostrar quais documentos foram enviados à LLM
- [ ] Explicar por que uma resposta foi considerada fiel ou não
- [ ] Alterar um parâmetro e prever o efeito
- [ ] Fazer uma pequena modificação no código ou na configuração experimental

---

## Critérios e pesos da nota (referência)

| Componente | Peso | Estado |
|---|---|---|
| Indexação e recuperação lexical | 10% | Implementado; corrigir o recálculo de `avgdl`/cópias por consulta e gerar as estatísticas |
| Tolerância a erros | 10% | Implementado; falta gerar os resultados e a análise |
| Recuperação semântica | 10% | Implementado; falta a versão do modelo e os resultados |
| Busca híbrida | 10% | Implementado; falta o tempo da fusão e os resultados |
| Reranking | 10% | Implementado; falta a análise dos 4 casos |
| Implementação e avaliação do RAG | 20% | **Não iniciado** |
| Avaliação quantitativa, análise crítica e reprodutibilidade | 20% | Métricas validadas; faltam as análises por consulta, o README e os CSVs na entrega |
| Compreensão individual / defesa | 10% | — |
