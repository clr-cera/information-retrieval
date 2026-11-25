# O que falta fazer (TP2)

Situação em 25/11/2026. Prazo registrado no checklist: **26/11/2026, 23:59**.

Tudo o que podia ser feito automaticamente está pronto: os 15 requisitos estão implementados e executados, os resultados estão em `result/tp2/`, e o relatório (`docs/report/`) tem todas as seções, com 15 de 20 páginas. O que falta depende do grupo, principalmente a **avaliação humana do RAG**, que o enunciado exige que seja feita por pessoas.

Detalhes de cada requisito: [`TP2_CHECKLIST.md`](TP2_CHECKLIST.md). Histórico: [`changes.md`](changes.md).

---

## 1. Avaliação humana do RAG (requisito 13) — obrigatório

Arquivos em `result/tp2/rag_avaliacao/`:

| Arquivo | Para quê |
|---|---|
| `planilha_avaliador1.csv`, `planilha_avaliador2.csv` | Uma planilha por integrante, com as 20 respostas embaralhadas e sem indicar se usaram RAG |
| `documentos_por_consulta.md` | Os 5 documentos de cada consulta, para julgar a fidelidade |
| `chave_NAO_ABRIR_antes_de_avaliar.csv` | Diz qual resposta é de qual condição. **Não abrir antes de terminar as notas.** |

Passos:

1. Cada integrante abre **a sua** planilha (no LibreOffice ou no Google Sheets) e, para cada resposta, preenche as colunas `fidelidade`, `completude`, `utilidade` e `rastreabilidade` com **0, 1 ou 2**, e a justificativa de cada nota nas colunas `*_justificativa`. Avaliem de forma independente, sem conversar sobre as notas.
   - **Fidelidade:** compare a resposta com os 5 documentos da consulta (em `documentos_por_consulta.md`). Vale também para respostas que não citam fontes.
     - 0 = afirmações importantes não sustentadas ou contraditórias
     - 1 = parcialmente sustentada
     - 2 = afirmações principais sustentadas pelos documentos
   - **Completude:**
     - 0 = não responde aos aspectos principais
     - 1 = responde parcialmente
     - 2 = cobre adequadamente o que pode ser respondido
   - **Utilidade:**
     - 0 = não atende à necessidade da pergunta
     - 1 = parcialmente útil
     - 2 = responde diretamente à necessidade
   - **Rastreabilidade:**
     - 0 = não é possível identificar as fontes
     - 1 = só parte das afirmações pode ser associada às fontes
     - 2 = as afirmações principais podem ser associadas aos doc_ids

     Numa resposta sem nenhuma fonte, pode deixar `N/A`. O script marca a rastreabilidade da condição sem RAG como N/A de qualquer forma, como exige o enunciado.
2. Salve como CSV, mantendo as colunas.
3. Junte as notas:
   ```bash
   uv run src/scripts/evaluate_rag.py merge --sheets result/tp2/rag_avaliacao/planilha_avaliador1.csv result/tp2/rag_avaliacao/planilha_avaliador2.csv
   ```
   O script confere se toda nota é 0, 1 ou 2 e tem justificativa. As notas da **primeira** planilha vão para o `rag_experiment.csv`. O script também calcula as médias por condição e a concordância entre os dois avaliadores, e grava tudo em `result/tp2/rag_evaluation_summary.md`.
4. Confira que todos os arquivos estão completos:
   ```bash
   uv run src/scripts/check_results.py
   ```
   Deve terminar com "All standardized result files are complete."

## 2. Completar o relatório com a avaliação humana

Todos os pontos estão marcados com `// TODO` nos arquivos `.typ`. Eles não aparecem no PDF.

- [ ] `docs/report/chapters/results/rag.typ`: copiar as médias e a concordância de `rag_evaluation_summary.md` para a tabela "Médias da avaliação humana" e escrever a discussão: o efeito da recuperação sobre a fidelidade, a completude e a disponibilidade de evidências, e a falta de fontes na condição sem RAG.
- [ ] `docs/report/chapters/results/failure_analysis.typ`: o caso "o RAG não ajudou" (PLAIN-2850) já está escrito. Escolher pelas notas **uma consulta em que o RAG melhorou claramente** e **uma com pouca diferença**, e analisar cada uma no mesmo formato. Para isso, usar os documentos enviados (`rag_stage_trace.md`), o que a resposta usou e as notas e justificativas.
- [ ] `docs/report/chapters/conclusion.typ`: acrescentar a conclusão da avaliação humana.
- [ ] Recompilar e conferir o limite de **20 páginas** (as referências não contam). Hoje são 15 (a última com as referências), então há folga de cerca de 4 páginas:
  ```bash
  typst compile docs/report/main.typ
  ```

## 3. Outros ajustes no relatório

- [ ] **Emails no cabeçalho** (exigência do enunciado): em `docs/report/main.typ`, trocar `<email Ariel>` e `<email Clara>` pelos emails reais.
- [ ] **Uso de ferramentas de IA:** revisar `docs/report/chapters/ai_use.typ`, que é um rascunho sobre o uso do Claude Code, e completar com o uso de cada integrante.
- [ ] Apagar os comentários `// TODO` que já foram resolvidos, recompilar e ler o PDF inteiro uma vez.

## 4. Preparação para a defesa individual

Qualquer integrante pode ser chamado a explicar qualquer parte. O material de estudo é [`docs/explanation/`](explanation/) (`typst compile docs/explanation/main.typ`), em especial o capítulo "Preparação para a defesa". Pratiquem:

- [ ] mostrar como o índice invertido é construído e consultado (`PostingList` e `ProbabilisticModel`, em `src/ir/lexical.py`);
- [ ] calcular o RRF de um documento à mão a partir das colunas `rank` de `results_lexical.csv` e `results_semantic.csv` (k = 10);
- [ ] justificar as mudanças de posição após o reranking (os 4 casos em `result/tp2/reranking_analysis.md`);
- [ ] mostrar quais documentos foram enviados à LLM (coluna `context_doc_ids` do `rag_experiment.csv`) e explicar por que uma resposta foi considerada fiel ou não;
- [ ] mudar um parâmetro no `config/tp2_experiment.json` (por exemplo `rrf_k` ou `bm25_b`), prever o efeito e rodar o script correspondente.

## 5. Entrega no Moodle

- [ ] **Commit:** nada do trabalho desta etapa foi commitado ainda. Revisar com `git status` e commitar.
- [ ] Montar o `.zip` com o código (`src/`, `config/`, `pyproject.toml`, `uv.lock`, `README.md`), os resultados (`result/tp2/`) e o relatório em PDF (`docs/report/main.pdf`). O enunciado exige que os CSVs estejam **dentro** do arquivo entregue; um link para o repositório não substitui a entrega.
- [ ] **Não incluir:** `data/` (dataset e embeddings, que são regeneráveis), `.venv/`, `result/tp2/old_k2_b0/` e qualquer chave ou senha.

## 6. Decisões opcionais (não exigidas)

Estes itens podem melhorar o trabalho, mas não são obrigatórios. Os três últimos mudam resultados e exigem rodar tudo de novo:

- Não implementado e citado no relatório:
  - robustez do sistema semântico às consultas com erro;
  - divisão dos documentos em trechos (chunking) no RAG.
- Corrigir o **token vazio** da tokenização: a pontuação isolada vira o termo `""`, presente em 1.513 documentos.
- Corrigir a junção de palavras com **hífen** (`shelf-life` → `shelflif`), que causou falhas do BM25 analisadas no relatório.
- Implementar um **desempate explícito** no BM25.
