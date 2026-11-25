== Retrieval-Augmented Generation (RAG)

O pipeline de RAG é: consulta → recuperação híbrida → reranking → seleção de contexto → LLM → resposta. A unidade de contexto é o documento do `corpus.jsonl` inteiro (título + texto), sem divisão em trechos, o que mantém a correspondência direta com os qrels. O contexto são os *5 primeiros documentos após o reranking*, cada um precedido do seu identificador (por exemplo, `[MED-2991]`).

=== Modelo de linguagem

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (auto, 1fr),
      align: (left, left),
      table.header([*Item*], [*Valor*]),
      [Modelo], [Qwen3 com 4 bilhões de parâmetros (`qwen3:4b` no Ollama, digest `359d7dd4bcda`), quantizado em 4 bits (Q4_K_M)],
      [Execução], [local, com Ollama 0.40.6, em CPU (AMD Ryzen 7 5700U, sem GPU); sem custo],
      [Parâmetros], [temperatura 0, seed 42, janela de contexto de 16.384 tokens e no máximo 4.096 tokens gerados],
      [Raciocínio], [o modelo raciocina antes de responder; o raciocínio vem separado e só a resposta final é registrada],
      [Idioma], [inglês nas duas condições (os documentos e as perguntas estão em inglês)],
      [Tamanho da resposta], [até 150 palavras, pedido no prompt das duas condições],
    )
  },
  caption: [Configuração da LLM.],
) <tab-llm>

A temperatura 0 e a seed fixa tornam a geração reprodutível. O limite de 4.096 tokens inclui o raciocínio e a resposta; todas as respostas terminaram antes desse limite. A integração usa a API HTTP do Ollama (`src/ir/rag.py`), chamada apenas com a biblioteca padrão do Python.

=== Experimento sem RAG × com RAG

São usadas as 10 consultas fixas do enunciado, sorteadas com seed 42 entre as 42 consultas do test formuladas como pergunta. O código reproduz o sorteio e confere que a lista é a mesma do enunciado. Cada consulta é respondida duas vezes, com o mesmo modelo e os mesmos parâmetros:

- *Condição A (sem RAG):* a LLM recebe somente a pergunta e não tem acesso à coleção NFCorpus.
- *Condição B (com RAG):* a LLM recebe a pergunta e os 5 documentos, com a instrução de basear todas as afirmações nos documentos, citar as fontes usadas pelos identificadores entre colchetes e dizer claramente quando os documentos não têm evidência suficiente.

Os prompts, os identificadores dos documentos enviados e as respostas estão no `rag_experiment.csv`.
