# Registro de alterações (TP2)

Alterações feitas no repositório, da mais recente para a mais antiga. Cada entrada diz o que mudou, por quê e como foi verificado.

---

## 26/11/2026 — Avaliação do RAG concluída e relatório finalizado

- **O quê:**
  - Nova `result/tp2/rag_avaliacao/planilha_avaliador_llm.csv`: notas e justificativas do Claude como **avaliador LLM declarado**, feitas sem consultar a planilha da avaliadora humana. Não é uma avaliação cega: o modelo conhecia as condições e tinha feito a ficha de evidências.
  - Merge: `evaluate_rag.py merge --sheets planilha_avaliador2.csv planilha_avaliador_llm.csv`. As notas finais do `rag_experiment.csv` são as da avaliadora humana (planilha 2, Clara). A `planilha_avaliador1.csv` (Ariel) não foi usada nem alterada.
  - Médias (humana, A → B): fidelidade 0,60 → 2,00; completude 1,70 → 1,90; utilidade 1,80 → 1,80; rastreabilidade 2,00 (B). Concordância humano × LLM: 90%, 60%, 60% e 100%; as 18 discordâncias são todas com a nota do LLM mais baixa, 14 na condição A.
  - Relatório: tabela de médias e concordância, discussão (fidelidade, utilidade, falta de fontes, concordância e a ressalva da ficha), notas nos 3 casos da análise de falhas, conclusão do RAG e "Uso de IA" com a segunda avaliação. Removidos os TODOs e o quadro "O QUE FALTA FAZER".
- **Por quê:** pedido do Ariel para concluir a avaliação. Ele pediu que eu preenchesse a planilha do avaliador 1 como se fosse dele. Em vez disso, as notas foram dadas como avaliação de LLM declarada no relatório, para não apresentar notas de IA como humanas.
- **Verificação:** `check_results.py` termina com "All standardized result files are complete."; `typst compile docs/report/main.typ` sem erros, 17 páginas; os números do texto conferidos com `rag_evaluation_summary.md` e `rag_experiment.csv`. A escolha dos 3 casos foi confirmada pelas notas humanas (PLAIN-2750: 0/1/1 → 2/2/2; PLAIN-270: 1/2/2 → 2/2/2; PLAIN-2850: 0/2/2 → 2/2/1).
- **Docs:** `PENDENCIAS.md` reescrito (só revisão e entrega), checklist e explicação atualizados.

---

## 26/11/2026 — Ficha de evidências e relatório do RAG sem depender das notas

- **O quê:**
  - Nova `result/tp2/rag_avaliacao/ficha_evidencias.md`: para cada item R01–R20, as afirmações principais da resposta classificadas contra os 5 documentos da consulta (apoiada, parcial, sem apoio, contradita), as citações e os documentos relevantes não usados. Não traz notas nem a condição.
  - `results/rag.typ`: nova comparação qualitativa das afirmações com os documentos. Sem RAG, três respostas contradizem os documentos (PLAIN-2750, PLAIN-2470, PLAIN-68); com RAG, as afirmações são rastreáveis, com imprecisões pontuais (PLAIN-2850, PLAIN-2750, PLAIN-2430) e omissões (MED-1338, MED-3680).
  - `results/failure_analysis.typ`: dois casos novos, "RAG melhorou claramente" (PLAIN-2750) e "pouca diferença" (PLAIN-270), escolhidos pela ficha. O TODO pede para conferir a escolha e acrescentar as notas.
  - `conclusion.typ`: conclusão qualitativa do RAG. `ai_use.typ`: ficha declarada como uso de IA. Quadro "O QUE FALTA FAZER" atualizado.
- **Por quê:** pedido do grupo para adiantar tudo o que não depende das notas humanas. As médias, a concordância e as notas dos casos continuam pendentes, porque dependem das planilhas preenchidas pelos integrantes.
- **Verificação:** `typst compile docs/report/main.typ` sem erros; 17 páginas (a última com as referências). Cada afirmação da ficha e do relatório foi conferida contra o texto dos documentos em `documentos_por_consulta.md`; tempos de geração do caso PLAIN-270 tirados de `rag_generations.json`.
- **Atenção:** as seções de RAG e de análise de falhas revelam as condições; os avaliadores devem lê-las só depois das notas (aviso no guia e no quadro do PDF).
- **Docs:** `PENDENCIAS.md`, `TP2_CHECKLIST.md` e `AVALIACAO_HUMANA_RAG.md` atualizados.

---

## 26/11/2026 — Emails no cabeçalho e uso de IA

- **O quê:** emails reais (arielalves@usp.br e claraernestodecarvalho@usp.br) no cabeçalho do relatório (`docs/report/main.typ`); item removido do quadro "O QUE FALTA FAZER". Em `chapters/ai_use.typ`, acrescentados dois usos do Claude Code: o material de estudo `docs/explanation/` e a verificação de que o contexto do RAG é o top-5 do ranking final. O TODO da seção continua, para o grupo completar e declarar como as notas do RAG foram atribuídas.
- **Por quê:** pendências do relatório que não dependem da avaliação humana.
- **Verificação:** `typst compile docs/report/main.typ` sem erros; 15 páginas; emails aparecem na primeira página. A explicação também foi recompilada.
- **Ainda pendente:** avaliação humana (planilhas com 2 de 80 notas), tabela de médias, dois casos da análise de falhas, conclusão do RAG, revisão final e entrega.
- **Docs:** checklist (cabeçalho marcado como feito), `PENDENCIAS.md` e explicação atualizados.

---

## 26/11/2026 — Explicação do projeto enxugada (51 → 21 páginas)

- **O quê:** `docs/explanation/` reescrito para cobrir conceitos, fluxos e o papel de cada arquivo, sem descrever função por função.
  - Removido o capítulo "Recursos de Python usados no código" e todas as fichas de função (o helper `funcao` saiu do `estilo.typ`).
  - Pré-processamento, índice invertido e BM25 juntos em um capítulo (`05_lexical.typ`); capítulos renumerados de 01 a 12.
  - Cada módulo de `src/ir/` descrito em poucos parágrafos ("o que o código faz"); os scripts numa tabela única com a ordem de execução.
  - Mantidos: teoria, exemplos calculados (métricas, BM25, RRF), escolhas no dev, casos do reranking, caso PLAIN-2850, resultados e perguntas da defesa (as "outras perguntas" viraram tabela). Removidos: tabela de Levenshtein, detalhes de imports, glossário e tabela de imports.
- **Por quê:** pedido do grupo; o documento estava longo demais para estudo.
- **Verificação:** `typst compile docs/explanation/main.typ` sem erros nem avisos; 21 páginas; referências cruzadas entre capítulos resolvidas. Nenhum número novo foi introduzido (todos vêm da versão anterior). Cópia dos capítulos antigos guardada fora do repositório.
- **Docs:** descrição da explicação atualizada no `README.md`.

---

## 26/11/2026 — Guia da avaliação humana do RAG

- **O quê:** novo `docs/AVALIACAO_HUMANA_RAG.md`, um guia para preencher as planilhas de `result/tp2/rag_avaliacao/`. Ele cobre:
  - os arquivos e como abrir o CSV;
  - o passo a passo de cada pergunta;
  - cada critério com tabela de notas e casos especiais (respostas sem citações, falta de evidência, N/A);
  - um exemplo inventado de justificativa;
  - as regras de validação do script (célula vazia vira N/A sem aviso) e os comandos `merge` e `check_results.py`.
- **Por quê:** pedido do grupo, para ter as instruções da avaliação num documento.
- **Docs:** link no `PENDENCIAS.md` (seção 1) e no `README.md` (texto de pendências e árvore de pastas).

---

## 25/11/2026 — Seção "O QUE FALTA FAZER" no relatório

- **O quê:** `docs/report/main.typ` ganhou, antes da Introdução, uma seção sem número, "O QUE FALTA FAZER", em um quadro vermelho. Ela lista as 8 pendências do grupo: avaliação humana do RAG, tabela de médias, 2 casos de falha, conclusão do RAG, emails, uso de IA, revisão final e entrega. O comentário no código e o próprio quadro avisam que a seção deve ser apagada antes da entrega.
- **Por quê:** pedido do grupo, para ver as pendências direto no PDF.
- **Verificação:** compila sem erros; continua com 15 páginas.
- **Docs:** item "apagar a seção O QUE FALTA FAZER" incluído em `PENDENCIAS.md` e no checklist.

---

## 25/11/2026 — Relatório enxugado (19 → 15 páginas)

- **O quê:** revisão de todos os capítulos de `docs/report/` para cortar repetições e detalhes desnecessários, sem remover nada que o enunciado exige.
  - Uma única tabela com os quatro sistemas (`tab-all-systems`, em "Lexical × semântico") substitui as três tabelas de médias que se repetiam (lexical × semântico, híbrido e reranking).
  - Tabelas do ajuste do $k$ do RRF, da escolha do cross-encoder e da posição do MED-4166 viraram frases com os mesmos números.
  - Truncamento do bi-encoder entrou na tabela de configuração da recuperação semântica.
  - Removidos: histórico da versão antiga do BM25 (cópias por consulta), estatísticas secundárias do índice (57,9% de termos únicos, maior posting list), comparação 86 × 82 com o TF-IDF, lotes de 32, explicação dos trigramas, observações sobre documentos duplicados, tamanho da lista fundida no RRF e outras frases repetidas.
  - Avaliação: "Modelos e parâmetros" e "Ambiente computacional" juntos em uma subseção; protocolo condensado em um parágrafo.
  - Análises por consulta (6 consultas, 4 casos do reranking, erros ortográficos e PLAIN-2850), conclusão e uso de IA reescritos de forma mais curta, com as mesmas evidências.
- **Por quê:** pedido do grupo para enxugar o relatório e deixar folga para a avaliação humana do RAG.
- **Verificação:** `typst compile docs/report/main.typ` sem erros; 15 páginas (a última com as referências); referências cruzadas conferidas. Nenhum número novo foi introduzido; os TODOs da avaliação humana continuam no lugar. Cópia dos capítulos antigos guardada fora do repositório.
- **Docs:** `TP2_CHECKLIST.md`, `PENDENCIAS.md` e `README.md` atualizados com a nova contagem de páginas.

---

## 25/11/2026 — Explicação atualizada, pendências e README

- **`docs/explanation/` atualizada com o código atual (51 páginas):**
  - novo capítulo 11, "RAG": teoria (LLM, raciocínio, RAG, experimento, avaliação às cegas), Ollama e o modelo, `src/ir/rag.py` (constantes e funções), `run_rag.py`, `evaluate_rag.py` (`prepare`/`merge`), resultados e o caso PLAIN-2850;
  - capítulos 12 a 14 renumerados;
  - estrutura (cap. 2) reescrita: 5 módulos, tabela com os 15 scripts, Ollama, config com a LLM, resultados versionados e documentos de `docs/`;
  - Python (cap. 3): `urllib.request` e `random.Random`;
  - reranking (cap. 10): o que os 4 casos mostram;
  - scripts (cap. 12): ordem completa e os scripts novos;
  - testes e resultados (cap. 13): 77 testes, `test_rag.py`, RAG e o que falta;
  - defesa (cap. 14): respostas sobre documentos enviados, fidelidade, LLM, `num_ctx`, avaliação às cegas e falhas do RAG.
- **`docs/dataset_validation.md` removido:** as contagens, a origem dos dados, a conferência das métricas e a auditoria dos splits estão no relatório (seção Avaliação) e na explicação. As referências no checklist foram atualizadas.
- **Novo `docs/PENDENCIAS.md`:** o que falta o grupo fazer, passo a passo:
  - avaliação humana do RAG (critérios, arquivos e comandos);
  - itens do relatório que dependem dela;
  - emails e uso de IA;
  - preparação para a defesa;
  - entrega no Moodle (o que incluir e o que não incluir; nada commitado ainda);
  - decisões opcionais.
- **README:** estado atualizado, link para as pendências, árvore com `rag.py` e `PENDENCIAS.md`, tabela de módulos com `rag.py`, instalação do Ollama e contagem de testes.

## 25/11/2026 — Requisitos 9 a 15 e enxugamento do relatório

**Código novo** (estilo simples: laços explícitos, funções pequenas, só biblioteca padrão onde possível):
- `src/ir/rag.py`: prompts das condições A (só a pergunta) e B (pergunta + 5 documentos com identificadores, instrução para usar só os documentos, citar as fontes e declarar falta de evidência) e chamada à LLM local pela API HTTP do Ollama, com `urllib` e `json`. Parâmetros:
  - temperatura 0, seed 42, `num_predict` 4096 e `num_ctx` 16384 (o padrão do Ollama cortaria o prompt);
  - `think: true`, porque o `qwen3:4b` instalado é a variante que sempre raciocina. O raciocínio vem separado, e só a resposta final é registrada.
- `src/scripts/run_rag.py`: lê o top-5 do `results_reranking.csv`, confere a amostra do enunciado, gera as 20 respostas e grava `rag_experiment.csv` e `rag_generations.json` a cada resposta.
- `src/scripts/evaluate_rag.py`:
  - `prepare`: P@5/R@5/Hit@5, rastreamento por estágio (`rag_stage_trace.md`) e avaliação às cegas (planilhas embaralhadas por avaliador, documentos por consulta e chave separada);
  - `merge`: valida as notas, grava no `rag_experiment.csv` (rastreabilidade N/A na condição A), e calcula as médias por condição e a concordância.
- `src/scripts/analyze_reranking.py`: seleciona os 4 casos do requisito 10 e grava `reranking_analysis.md`.
- `src/scripts/check_results.py`: verifica os 7 arquivos padronizados.
- `src/tests/test_rag.py`: 3 testes dos prompts. São 77 testes passando.
- Nenhum código existente foi alterado.

**Configuração e execução:**
- `config/tp2_experiment.json`: `llm: qwen3:4b`, `llm_temperature: 0`, `llm_max_tokens: 4096`, `rag_language: en`.
- RAG executado: 20 respostas, todas terminadas antes do limite; A levou 61 s em média e B, 235 s.
- Recuperação do contexto: P@5 = 0,44, R@5 = 0,106, Hit@5 = 0,90.
- `.gitignore`: os arquivos finais de `result/tp2/` passam a ser versionados (exigência da entrega); as pastas auxiliares continuam fora.

**Relatório:**
- Novas seções:
  - metodologia do reranking (com a versão do modelo) e do RAG;
  - resultados do reranking: tabela dos 4 sistemas e 4 casos, com causas verificadas nos dados (hífens `shelflif`/`betelnut`, betel × castanhas, myelopathy × myeloma, duplicados);
  - tempos de todas as etapas;
  - RAG: recuperação e fatos objetivos das respostas; a tabela da avaliação humana ficou pendente;
  - análise de falhas: PLAIN-2850, com o documento que responde perdido por paráfrase em todos os estágios e rebaixado pelo reranking; os outros 2 casos ficaram pendentes;
  - introdução, conclusão, rascunho do uso de IA e referências.
- **Enxugamento:**
  - capa e sumário trocados por um cabeçalho na primeira página;
  - metodologia de pré-processamento, índice, BM25, correção ortográfica e semântica condensada, mantendo os números exigidos (a tabela de empates do BM25 virou texto);
  - tabela de modelos e parâmetros da Avaliação virou parágrafo.
- Resultado: de 23 para 19 páginas com todas as seções, e cerca de 1 página livre para o que falta.
- **Pendências do grupo:** avaliação humana do RAG (planilhas em `result/tp2/rag_avaliacao/`), os 2 casos de falha que dependem dela, os emails do cabeçalho e a revisão da seção de uso de IA.

## 25/11/2026 — Requisito 8 (busca híbrida com RRF)

- **Medições com um script no scratchpad**, a partir dos `results_*.csv` do test, sem alterar o código:
  - tempo da fusão: 0,07 ms por consulta (mediana de 20 repetições);
  - a fusão recalculada é idêntica ao `results_hybrid.csv`;
  - sobreposição dos top-100: 22 documentos em média; lista fundida com 145 documentos;
  - composição do top-10 híbrido: 6,5 documentos estão nos dois rankings, 2,6 só no semântico e 0,9 só no lexical;
  - relevantes no top-100: lexical 6,5, semântico 8,0, união 9,7;
  - por consulta, o NDCG@10 do híbrido fica acima dos dois sistemas em 42 consultas, entre eles em 272 e abaixo de ambos em 9;
  - oráculo (melhor sistema de cada consulta): 0,3795;
  - consultas com NDCG@10 zero: 89 no híbrido, contra 102 (lexical) e 100 (semântico);
  - empates do RRF entre a 10ª e a 11ª posição: 30 consultas.
- **Relatório:**
  - `docs/report/chapters/methodology/hybrid.typ`: fórmula, profundidade 100, por que usar posições, tabela do ajuste de k no dev e escolha de k = 10;
  - `docs/report/chapters/results/hybrid.typ`: tabela Lexical × Semântico × Híbrido no test e análise da complementaridade.
- O relatório passou a ter **21 páginas, acima do limite de 20**. Precisa ser enxugado.
- `docs/TP2_CHECKLIST.md`: seção 8 e itens do relatório marcados.
- Nenhum código foi alterado.

## 25/11/2026 — Requisito 7 (comparação lexical × semântica por consulta)

- **Novo script `src/scripts/analyze_lexical_vs_semantic.py`**, em estilo convencional:
  - lê o `metrics_per_query.csv` e os `results_lexical.csv`/`results_semantic.csv`;
  - calcula ΔNDCG@10 (semântico − lexical) e seleciona as 3 consultas com maior vantagem de cada lado, com desempate pelo identificador;
  - para cada uma, registra os termos e seu df, os relevantes alcançáveis pelo BM25 e o top-5 de cada sistema (score, grau, termos da consulta presentes com tf, número de tokens e truncamento, posição no outro sistema e título);
  - saída em `result/tp2/lexical_vs_semantic_analysis.md`.
- **Hipóteses verificadas com um script no scratchpad antes de escrever:**
  - divisão em subpalavras (`kohlrabi` → `ko ##hl ##ra ##bi`; `grapefruit` → `grape ##fr ##uit`; `cadaverine` → `cad ##aver ##ine`);
  - a primeira ocorrência de "kohlrabi" no documento relevante está no token 34, dentro do limite, então o truncamento foi descartado como causa;
  - formas de "low-carbohydrate" nos relevantes e o termo `lowcarbohydr`;
  - stems `frozen` × `freez`;
  - o "D" removido como stopword;
  - contexto de "shed light" nos documentos do topo do BM25;
  - MED-3207 e MED-398 são duplicados.
- **Relatório (`docs/report/chapters/results/lexical_vs_semantic.typ`):** subseção "Análise por consulta" com as 6 consultas (tabela compacta do top-5 dos dois sistemas lado a lado e análise de cada uma) e uma síntese.
- O relatório tem 19 páginas.
- README e `docs/TP2_CHECKLIST.md` (seção 7 e item do relatório) atualizados.
- Nenhum código existente foi alterado.

## 25/11/2026 — Requisito 6 (avaliação da recuperação)

- **Conferência dos resultados finais**, feita com um script no scratchpad, sem alterar o código nem os resultados. Os rankings dos 4 sistemas (`results_*.csv`) foram reavaliados com o `ir_measures`, consulta a consulta, usando a posição como score, para preservar a ordem gravada:
  - a diferença máxima em relação ao `metrics_per_query.csv` foi de 3×10⁻¹⁶;
  - a média de `AP10` coincide com o MAP@10 do `retrieval_summary.json`;
  - a coluna `relevance` confere com os qrels;
  - há 323 consultas por sistema.
- **Relatório:**
  - `docs/report/chapters/evaluation.typ` escrito, com as 5 subseções:
    - conjunto de dados e splits (tabela com consultas, julgamentos, relevantes por consulta e graus);
    - métricas (definições e convenções, e conferência com o `ir_measures`);
    - modelos e parâmetros (tabela da configuração final);
    - ambiente computacional;
    - protocolo experimental, com a declaração de que os qrels do test não foram usados para ajustes e as duas exceções do enunciado;
  - `docs/report/chapters/results/lexical_vs_semantic.typ`: resultados globais lexical × semântico no test e comparação do NDCG@10 por consulta. A análise das 6 consultas (requisito 7) ficou pendente.
- O relatório passou a ter 17 páginas (o limite é 20, sem contar as referências).
- `docs/TP2_CHECKLIST.md`: seção 6 e item "d. Avaliação" do relatório marcados como concluídos.
- Nenhum código foi alterado.

## 25/11/2026 — Explicação completa do projeto (`docs/explanation/`)

- Novo documento Typst (`docs/explanation/main.typ`, `estilo.typ` e 13 capítulos em `chapters/`; PDF de 45 páginas). Público: quem cursa a disciplina, por exemplo para estudar para a defesa. Capítulos:
  1. Visão geral e NFCorpus
  2. Estrutura do repositório e configuração
  3. Recursos de Python usados no código
  4. Métricas
  5. `ir/data.py`
  6. Pré-processamento
  7. Índice invertido e BM25
  8. Correção ortográfica
  9. Busca semântica
  10. Busca híbrida e reranking
  11. Scripts
  12. Testes e resultados
  13. Perguntas da defesa e glossário
- Cada capítulo traz a teoria e depois o código, função por função, com os imports explicados.
- Os exemplos numéricos (métricas, BM25, RRF, k-gramas e Jaccard, tokenização) foram calculados com o próprio código do projeto. A tabela de Levenshtein foi conferida com `levenshtein_distance`.
- Os dados medidos citados vêm dos resultados de 25/11/2026: distribuição dos graus de relevância, truncamento, tempos e dimensões dos modelos.
- README: `docs/explanation/` incluído na árvore e na seção do relatório.

---

## 25/11/2026 — Requisito 5 (recuperação semântica)

- **Ajuste no dev:** `tune_semantic.py` reexecutado sem `--update-config` (`result/tp2/semantic_tuning_dev.csv`). `all-MiniLM-L6-v2` teve NDCG@10 de 0,3024 contra 0,2718 do `multi-qa-MiniLM-L6-cos-v1`; a escolha do config foi mantida.
- **Medições com um script no scratchpad, sem alterar o código nem o cache:**
  - revisão do modelo no Hugging Face (`1110a243fdf4706b3f48f1d95db1a4f5529b4d41`);
  - versões das bibliotecas e arquitetura (mean pooling + normalização);
  - tokens por documento: média de 357; 2.864 de 3.633 truncados (78,8%); 32,2% dos tokens descartados;
  - tempo limpo dos embeddings: 109,7 s em CPU. O valor do cache (154 s) estava inflado; os vetores recalculados são idênticos aos do cache.
- **Relatório:** `docs/report/chapters/methodology/semantic.typ`, com configuração, versão, indexação e busca, tempos, truncamento e escolha do modelo no dev.
- `docs/TP2_CHECKLIST.md`: seção 5 marcada como concluída.
- **Nenhum código alterado.** A versão do modelo ficou registrada no relatório, não no código.

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
