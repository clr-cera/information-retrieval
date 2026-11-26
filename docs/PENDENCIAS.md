# O que falta fazer (TP2)

Situação em 26/11/2026. Prazo registrado no checklist: **26/11/2026, 23:59**.

Os 15 requisitos estão implementados e executados, os resultados estão em `result/tp2/` (`check_results.py` termina com "All standardized result files are complete.") e o relatório (`docs/report/`) está completo, com 17 de 20 páginas, sem TODOs e sem o quadro "O QUE FALTA FAZER".

Detalhes de cada requisito: [`TP2_CHECKLIST.md`](TP2_CHECKLIST.md). Histórico: [`changes.md`](changes.md).

---

## 1. Avaliação do RAG — feita

- Avaliação humana: `planilha_avaliador2.csv` (Clara), completa. As notas finais do `rag_experiment.csv` são dela.
- Segunda avaliação: `planilha_avaliador_llm.csv`, feita pelo Claude como avaliador LLM **declarado no relatório** (não cega, porque o modelo conhecia as condições e fez a ficha de evidências). Serve só para a concordância.
- `planilha_avaliador1.csv` (Ariel) não foi usada; tem só 2 notas.
- Merge feito com `evaluate_rag.py merge --sheets planilha_avaliador2.csv planilha_avaliador_llm.csv` → `rag_evaluation_summary.md`.

## 2. Revisar antes de entregar

- [ ] Ler o PDF inteiro uma vez, em especial a seção do RAG (forma como as duas avaliações são descritas) e o "Uso de ferramentas de IA".
- [ ] Se o Ariel preferir avaliar também, preencher `planilha_avaliador1.csv` e refazer o merge com as duas planilhas humanas; aí a tabela e o texto da concordância precisam ser atualizados.
- [ ] Completar o "Uso de ferramentas de IA" se algum integrante usou IA fora do Claude Code.

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
