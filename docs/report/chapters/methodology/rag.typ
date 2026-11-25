== Retrieval-Augmented Generation (RAG)

O pipeline é: consulta → recuperação híbrida → reranking → seleção de contexto → LLM → resposta. O contexto são os *5 primeiros documentos após o reranking*, inteiros (título + texto, sem divisão em trechos, o que mantém a correspondência com os qrels), cada um precedido do seu identificador (por exemplo, `[MED-2991]`).

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
      [Parâmetros], [temperatura 0, seed 42, janela de contexto de 16.384 tokens, no máximo 4.096 tokens gerados (raciocínio + resposta; nenhuma resposta atingiu o limite); só a resposta final é registrada, sem o raciocínio],
      [Idioma e tamanho], [inglês nas duas condições (documentos e perguntas estão em inglês); até 150 palavras],
    )
  },
  caption: [Configuração da LLM, chamada pela API HTTP do Ollama (`src/ir/rag.py`).],
) <tab-llm>

São usadas as 10 consultas fixas do enunciado, sorteadas com seed 42 entre as 42 perguntas do test; o código reproduz o sorteio e confere a lista. Cada consulta é respondida duas vezes, com o mesmo modelo e os mesmos parâmetros:

- *Condição A (sem RAG):* a LLM recebe só a pergunta, sem acesso à coleção.
- *Condição B (com RAG):* a LLM recebe a pergunta e os 5 documentos. O prompt instrui o modelo a basear as afirmações nos documentos, citar as fontes pelos identificadores entre colchetes e dizer quando não houver evidência suficiente.

Os prompts, os documentos enviados e as respostas estão no `rag_experiment.csv`.
