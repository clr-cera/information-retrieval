#import "../estilo.typ": *

= RAG: geração de respostas (`ir/rag.py`) <cap-rag>

== Teoria

Uma *LLM* gera texto token a token a partir do que aprendeu no treinamento. Ela não consulta fontes e pode afirmar coisas erradas com segurança (*alucinações*), sem dizer de onde tirou a informação. No *RAG* (Retrieval-Augmented Generation), a LLM recebe, junto com a pergunta, os documentos recuperados pelo sistema de busca e a instrução de responder a partir deles. O que se espera ganhar:

- *fidelidade*: a resposta se apoia em evidências da coleção;
- *rastreabilidade*: a resposta cita as fontes, que podem ser conferidas;
- *honestidade*: se os documentos não respondem, a LLM pode dizer isso em vez de inventar.

A resposta só pode ser tão boa quanto o contexto: se a informação não chega aos 5 documentos, a LLM não tem como usá-la. Por isso as métricas do contexto (P\@5, R\@5, Hit\@5) importam tanto quanto o modelo.

== O experimento

Duas condições, com a mesma LLM e os mesmos parâmetros, nas 10 perguntas fixas do test:

- *A (sem RAG)*: só a pergunta;
- *B (com RAG)*: a pergunta e os 5 primeiros documentos após o reranking, cada um com seu identificador.

As 20 respostas recebem notas 0, 1 ou 2 em fidelidade, completude, utilidade e rastreabilidade, dadas por pessoas *às cegas* (quem avalia não sabe qual resposta usou RAG). O guia está em `docs/AVALIACAO_HUMANA_RAG.md`.

== A LLM e o arquivo `ir/rag.py`

A LLM é o `qwen3:4b` (Qwen3, 4 bilhões de parâmetros, quantizado em 4 bits, 2,5 GB), executado localmente pelo *Ollama*, que a oferece por uma API HTTP em `localhost:11434`. Roda em CPU, sem custo nem chave. O Qwen3 *raciocina* antes de responder; o raciocínio vem num campo separado, e só a resposta final é registrada.

O módulo, sem dependências externas, tem:

- os dois *prompts*: o da condição A traz só a pergunta; o da B traz as regras do enunciado (usar só os documentos, citar as fontes como `[MED-123]`, dizer quando não houver evidência), os 5 documentos no formato `[MED-2991] título e texto` e a pergunta. Ambos pedem até 150 palavras, em inglês;
- `ask_llm`, que chama a API com temperatura 0 e seed 42 (reprodutível), no máximo 4.096 tokens gerados (raciocínio + resposta) e janela de contexto de 16.384 tokens — o padrão do Ollama é menor, e um prompt maior seria cortado em silêncio, perdendo documentos. Devolve o texto, o tempo, os tokens e se a geração terminou normalmente.

== Os scripts do RAG

*`run_rag.py`* lê os 5 primeiros documentos de cada pergunta do `results_reranking.csv` (o contexto é exatamente o que o pipeline avaliado produziu), chama a LLM nas duas condições e grava `rag_experiment.csv` e `rag_generations.json` *após cada resposta*, para não perder o que já foi gerado se a execução parar.

*`evaluate_rag.py prepare`* calcula as métricas do contexto; faz o *rastreamento por estágio* (`rag_stage_trace.md`: a melhor posição de um relevante no lexical, no semântico, no híbrido e no reranking, mostrando onde um relevante se perdeu); e monta a avaliação às cegas: embaralha as 20 respostas com seed 42, numera de R01 a R20, grava uma planilha por avaliador, a *chave* (em arquivo separado) e os 5 documentos de cada pergunta, para julgar a fidelidade.

*`evaluate_rag.py merge --sheets ...`* valida as planilhas (toda nota 0, 1, 2 ou N/A, com justificativa), usa a chave para separar as condições, marca como N/A a rastreabilidade da condição A, grava as notas no `rag_experiment.csv` e calcula as médias por condição e, com duas planilhas, a concordância entre avaliadores.

== Resultados

#tabela(
  (auto, 1fr),
  [*Medida*], [*Resultado*],
  [Respostas], [20, todas terminadas antes do limite de tokens],
  [Tempo médio], [61 s sem RAG; 235 s com RAG (prompt de 53 para 2.294 tokens)],
  [Contexto], [P\@5 = 0,44, R\@5 = 0,106 (cerca de 44 relevantes por pergunta, só 5 enviados), Hit\@5 = 0,90],
  [Citações (B)], [de 1 a 4 documentos por resposta, todos entre os enviados],
  [Falta de evidência], [2 respostas com RAG declaram que os documentos não bastam (PLAIN-2850 e PLAIN-3342)],
  [Avaliação (0 a 2)], [fidelidade 0,60 → 2,00; completude 1,70 → 1,90; utilidade 1,80 → 1,80; rastreabilidade 2,00 com RAG. Notas de uma avaliadora humana; um LLM declarado fez a segunda avaliação, para a concordância],
)

*Um caso de falha — PLAIN-2850*, "More Antibiotics In White Meat or Dark Meat?", a única pergunta sem nenhum relevante no contexto (Hit\@5 = 0). A coleção tem a resposta: o MED-4166 mostra que um antibiótico se concentra mais no peito do que na coxa de frangos. Mas ele fala em "breast versus thigh muscle" e não usa "white", "dark" nem "meat"; fica em 29º no lexical, 14º no semântico, 11º no híbrido e 19º no reranking — fora do top-5. A geração não foi o problema: com RAG, a LLM diz que os documentos não trazem o dado; sem RAG, afirma que a cor da carne não muda o nível de antibiótico, o contrário do MED-4166. Lição: quando o RAG falha, é preciso seguir a informação pelos estágios antes de culpar a LLM.
