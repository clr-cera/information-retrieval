#import "../estilo.typ": *

= RAG: geração de respostas (`ir/rag.py`) <cap-rag>

== Teoria

=== Modelos de linguagem

Um *modelo de linguagem* (LLM) é uma rede neural treinada para prever o próximo token de um texto. Ao receber um *prompt*, ele gera a resposta um token por vez, cada um escolhido a partir dos anteriores. Tudo o que ele "sabe" vem dos textos vistos no treinamento: ele não consulta nenhuma fonte e pode afirmar coisas erradas com toda a segurança (as chamadas *alucinações*), sem indicar de onde tirou a informação.

Alguns modelos, como o Qwen3 usado aqui, *raciocinam* antes de responder: geram primeiro um texto de pensamento (planejar a resposta, conferir os documentos) e só depois a resposta final. Isso melhora a qualidade, mas aumenta o número de tokens gerados e o tempo.

=== Retrieval-Augmented Generation

O RAG combina recuperação e geração: em vez de responder só com o que aprendeu no treinamento, a LLM recebe junto com a pergunta os documentos mais relevantes encontrados pelo sistema de busca, com a instrução de responder a partir deles. As vantagens esperadas são:

- *fidelidade*: a resposta se apoia em evidências reais da coleção;
- *rastreabilidade*: a resposta cita de onde tirou cada informação, e quem lê pode conferir;
- *honestidade*: se os documentos não respondem à pergunta, a LLM pode dizer isso, em vez de inventar.

O custo é que a resposta só pode ser tão boa quanto os documentos recuperados: se a informação necessária não chega ao contexto, a LLM não tem como usá-la. Por isso a qualidade da recuperação (as métricas P\@5, R\@5 e Hit\@5 do contexto) importa tanto quanto o modelo.

=== O experimento

O enunciado compara duas condições, com a mesma LLM e os mesmos parâmetros, nas 10 perguntas fixas do test:

- *A (sem RAG)*: a LLM recebe só a pergunta.
- *B (com RAG)*: a LLM recebe a pergunta e os 5 primeiros documentos após o reranking, cada um com o seu identificador.

As respostas são avaliadas por pessoas, com notas 0, 1 ou 2 em fidelidade, completude, utilidade e rastreabilidade. Para não favorecer uma condição, a avaliação é *às cegas*: quem avalia não sabe qual resposta usou RAG.

== O modelo e o Ollama

O *Ollama* é um programa que baixa e executa LLMs no próprio computador e as oferece por uma API HTTP local. O modelo é o `qwen3:4b`: Qwen3 com 4 bilhões de parâmetros, *quantizado* em 4 bits (Q4_K_M), isto é, com os pesos guardados com menos precisão para ocupar só 2,5 GB e rodar em CPU. Não há custo nem chave de API.

== O código: `src/ir/rag.py`

Imports: `json` (montar o pedido e ler a resposta), `urllib.request` (fazer a chamada HTTP), `dataclass` (a classe da resposta) e `perf_counter` (medir o tempo). Nenhuma dependência externa.

Constantes:

#tabela(
  (auto, auto, 1fr),
  [*Constante*], [*Valor*], [*Significado*],
  [`OLLAMA_URL`], [`http://localhost:11434/api/chat`], [Endereço da API de conversa do Ollama.],
  [`LLM_SEED`], [42], [Seed da geração: com temperatura 0, garante a mesma resposta em outra execução.],
  [`ANSWER_WORD_LIMIT`], [150], [Tamanho máximo pedido para a resposta, igual nas duas condições.],
  [`REQUEST_TIMEOUT_SECONDS`], [1800], [Tempo máximo de espera por uma resposta (30 min).],
  [`CONTEXT_WINDOW_TOKENS`], [16384], [Janela de contexto do modelo. O padrão do Ollama é menor; um prompt maior seria cortado em silêncio, perdendo documentos.],
  [`SYSTEM_MESSAGE`], [texto], [Mensagem de sistema: "assistente que responde perguntas sobre nutrição e saúde".],
)

#funcao("class LLMAnswer(text, seconds, prompt_tokens, generated_tokens, finished)")[A resposta de uma chamada: o texto final, o tempo, os tokens do prompt e os gerados (raciocínio + resposta) e se a geração terminou normalmente (e não por atingir o limite de tokens).]

#funcao("def build_prompt_without_context(question: str) -> str")[Prompt da condição A: pede a resposta em inglês, em até 150 palavras, e traz a pergunta.]

#funcao("def build_prompt_with_context(question: str, documents: list[tuple[str, str]]) -> str")[
  Prompt da condição B. Começa pelas regras: usar só os documentos, citar as fontes pelos identificadores entre colchetes (por exemplo, `[MED-123]`) e dizer claramente quando não houver evidência suficiente — exatamente o que o enunciado pede. Depois vem cada documento no formato `[MED-2991] título e texto`, na ordem do ranking, e por fim a pergunta. As linhas são montadas numa lista e unidas com `"\n".join(...)`.
]

#funcao("def ask_llm(prompt, model, temperature, max_tokens) -> LLMAnswer")[
  Monta o pedido para a API de conversa do Ollama:
  - `stream: false`: a resposta vem inteira, de uma vez;
  - `think: true`: o raciocínio vem num campo separado (`message.thinking`), e o texto final, em `message.content`. O modelo instalado sempre raciocina; separar os dois é a forma de guardar só a resposta;
  - `options`: `temperature` (0, a escolha mais provável a cada token), `seed`, `num_predict` (no máximo 4.096 tokens gerados, somando raciocínio e resposta) e `num_ctx` (a janela de 16.384 tokens);
  - `messages`: a mensagem de sistema e o prompt.

  Envia com `urllib.request.urlopen`, mede o tempo e devolve um `LLMAnswer` com o texto final (sem espaços nas pontas), `prompt_eval_count` (tokens do prompt), `eval_count` (tokens gerados) e se `done_reason` é `"stop"` (terminou normalmente).
]

== O script `run_rag.py`

+ Lê do config o modelo, a temperatura e o limite de tokens.
+ Carrega o test e confere que `select_rag_query_ids` reproduz a amostra do enunciado.
+ `read_top_documents` lê os 5 primeiros documentos de cada consulta do `results_reranking.csv`, o ranking final do pipeline. Assim, o contexto é exatamente o que o sistema avaliado produziu.
+ Para cada consulta, monta os dois prompts, chama a LLM nas duas condições e guarda uma `RagExperimentRow` (com `context_doc_ids` vazio na condição A, registrando explicitamente que não há contexto) e as estatísticas da geração.
+ Grava `rag_experiment.csv` e `rag_generations.json` *depois de cada resposta* (`save_progress`), de modo que uma execução interrompida não perde o que já foi gerado.

A opção `--queries N` roda só as N primeiras consultas, útil para testar.

== O script `evaluate_rag.py`

Tem duas etapas, escolhidas pelo primeiro argumento.

*`prepare`* (depois do `run_rag.py`):
+ *Métricas do contexto*: P\@5, R\@5 e Hit\@5 dos 5 documentos enviados, com as funções de `ir.metrics` → `rag_retrieval_metrics.csv`.
+ *Rastreamento por estágio*: para cada consulta, a melhor posição de um relevante no lexical, no semântico, no híbrido e após o reranking, e quais relevantes entraram no top-5 (`best_relevant_position`) → `rag_stage_trace.md`. É a base da análise de falhas: mostra em que estágio um relevante se perdeu.
+ *Avaliação às cegas*: embaralha as 20 respostas com `random.Random(42).shuffle` e numera de `R01` a `R20`. Grava uma planilha por avaliador (pergunta e resposta, sem a condição, com colunas vazias para as notas e justificativas), a *chave* que liga cada item à consulta e à condição (num arquivo separado, para não ser aberto antes de avaliar) e um arquivo com os 5 documentos de cada consulta, que servem para julgar a fidelidade nas duas condições.

*`merge --sheets planilha1.csv [planilha2.csv]`* (depois das notas):
+ `read_sheet` lê cada planilha e confere que toda nota é 0, 1, 2 ou N/A e tem justificativa; se algo estiver errado, para e lista os problemas.
+ `scores_by_answer` usa a chave para saber a condição de cada item e marca a rastreabilidade da condição A como N/A (sem contexto não há fontes, como manda o enunciado).
+ Grava as notas da *primeira* planilha no `rag_experiment.csv`, calcula a média de cada critério por condição (ignorando N/A) e, com duas planilhas, a *concordância* entre os avaliadores: a fração de notas iguais e a diferença média → `rag_evaluation_summary.md`.

== Resultados

#tabela(
  (auto, 1fr),
  [*Medida*], [*Resultado*],
  [Respostas geradas], [20, todas terminadas antes do limite de tokens],
  [Tempo médio], [61 s sem RAG; 235 s com RAG (o prompt passa de 53 para 2.294 tokens e o modelo gera o dobro)],
  [Contexto], [P\@5 = 0,44 (2,2 relevantes em 5), R\@5 = 0,106, Hit\@5 = 0,90],
  [Citações (condição B)], [as 10 respostas citam de 1 a 4 documentos, todos entre os enviados (nenhuma fonte inventada)],
  [Falta de evidência], [2 respostas com RAG declaram que os documentos não bastam (PLAIN-2850 e PLAIN-3342)],
  [Avaliação humana], [pendente: o grupo preenche as planilhas (ver `docs/PENDENCIAS.md`)],
)

O R\@5 baixo é esperado: as 10 perguntas têm em média cerca de 44 relevantes, e só 5 documentos são enviados.

=== Um caso de falha: PLAIN-2850

"More Antibiotics In White Meat or Dark Meat?" é a única pergunta em que nenhum relevante chegou à LLM (Hit\@5 = 0). O rastreamento mostra onde a informação se perdeu. A coleção tem a resposta: MED-4166 (grau 2) mostra que um antibiótico se concentra mais no músculo do peito do que no da coxa de frangos. Mas o documento fala em "breast versus thigh muscle" e nunca usa "white", "dark" ou "meat"; dos 4 termos da consulta, só `antibiot` aparece nele. Ele fica em 29º no lexical, 14º no semântico, 11º no híbrido e cai para 19º no reranking; com o corte em 5, não é enviado.

A geração, porém, não foi o problema: a resposta com RAG diz que os documentos não trazem dados sobre resíduos de antibiótico em carne branca ou escura, enquanto a resposta sem RAG afirma com segurança que "a cor da carne não determina os níveis de antibiótico" — o contrário do que diz o MED-4166. O caso mostra que, quando o RAG falha, é preciso seguir a informação por todos os estágios antes de culpar a LLM.
