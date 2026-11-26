# Como fazer a avaliação humana do RAG

Guia para os dois integrantes preencherem as notas das respostas do RAG (requisito 13 do enunciado). Os arquivos ficam em `result/tp2/rag_avaliacao/`.

## 1. Os arquivos

| Arquivo | Uso |
|---|---|
| `planilha_avaliador1.csv` | Planilha do Ariel |
| `planilha_avaliador2.csv` | Planilha da Clara |
| `documentos_por_consulta.md` | Os 5 documentos enviados à LLM em cada pergunta. É a "verdade" contra a qual as respostas são julgadas. |
| `ficha_evidencias.md` | Apoio opcional: para cada item (R01 a R20), as afirmações principais da resposta e o que os documentos dizem sobre cada uma. Não traz notas. Feita com apoio de IA: confira nos documentos. |
| `chave_NAO_ABRIR_antes_de_avaliar.csv` | Diz quais respostas usaram RAG. **Não abrir antes de terminar as notas.** |

A planilha tem 20 linhas (R01 a R20), em ordem embaralhada. Cada uma das 10 perguntas aparece duas vezes: uma resposta sem RAG e outra com RAG. As colunas `query` e `answer` trazem a pergunta e a resposta. Cada avaliador preenche as outras 8 colunas: 4 notas e 4 justificativas.

## 2. Abrindo a planilha

**LibreOffice Calc:** abra o CSV e, na janela de importação, escolha:

- conjunto de caracteres **UTF-8**;
- separador **vírgula**;
- delimitador de texto **"**.

Para ler as respostas longas, selecione a coluna `answer` e marque *Formatar células › Alinhamento › Quebrar texto automaticamente*.

**Google Sheets:** use *Arquivo › Importar*. No fim, baixe com *Arquivo › Fazer download › CSV*.

## 3. Passo a passo de cada pergunta

1. Leia a pergunta (coluna `query`).
2. No `documentos_por_consulta.md`, procure o `query_id` (por exemplo, `## PLAIN-3342`) e leia os 5 resumos. Anote o que eles realmente dizem sobre a pergunta.
3. Encontre as duas linhas dessa pergunta na planilha.
4. Em cada resposta, separe as **afirmações principais**, normalmente de 2 a 4. Para cada uma, pergunte: "isto está nos documentos? Do mesmo jeito, só em parte ou ao contrário?" A `ficha_evidencias.md` já traz esse levantamento por item; use-a como ponto de partida e confira nos documentos.
5. Dê as notas e escreva as justificativas.

Não leiam as seções de RAG e de análise de falhas do relatório antes de terminar: elas dizem qual resposta é de qual condição.

Avalie as duas respostas de uma pergunta em sequência, para ler os documentos uma vez só.

## 4. Os critérios na prática

### Fidelidade: as afirmações batem com os 5 documentos?

| Nota | Quando dar |
|---|---|
| 2 | As afirmações principais estão nos documentos. |
| 1 | Parte está nos documentos, e parte não está lá ou está exagerada. |
| 0 | Afirmações importantes não aparecem nos documentos ou os contradizem. |

- Respostas **sem citações** também são julgadas contra os mesmos 5 documentos, como manda o enunciado. Uma resposta pode estar "certa" pelo conhecimento geral e ainda assim ter fidelidade baixa, se os documentos não a sustentam.
- Se a resposta diz "os documentos não trazem essa informação" e isso é **verdade**, essa afirmação é fiel.

### Completude: cobre o que dava para responder?

| Nota | Quando dar |
|---|---|
| 2 | Cobre adequadamente os aspectos que **podem** ser respondidos. |
| 1 | Responde parcialmente. |
| 0 | Não responde aos aspectos principais. |

Se os documentos não têm a resposta, uma resposta que admite isso e diz o que é possível dizer pode receber 2. Não penalize a resposta por não inventar.

### Utilidade: quem perguntou fica bem servido?

| Nota | Quando dar |
|---|---|
| 2 | Responde diretamente à necessidade da pergunta. |
| 1 | É parcialmente útil (por exemplo, vaga ou cheia de rodeios). |
| 0 | Não atende à necessidade. |

### Rastreabilidade: dá para ligar as afirmações aos `[MED-...]` citados?

| Nota | Quando dar |
|---|---|
| 2 | As afirmações principais têm citação, e o documento citado **realmente diz aquilo**. Confira pelo menos as citações principais. |
| 1 | Só parte das afirmações tem fonte, ou alguma citação aponta para o documento errado. |
| 0 | Há citações, mas não dá para associá-las às afirmações. |
| N/A | A resposta não cita nenhuma fonte. Justifique, por exemplo: "não cita fontes". |

O script marca N/A em todas as respostas sem RAG de qualquer forma, como exige o enunciado.

> As citações deixam claro qual resposta usou RAG; isso é inevitável. Julgue cada resposta pelo critério, sem pensar em qual condição "deveria" ganhar.

## 5. Justificativas

Basta uma frase curta e concreta, citando o documento quando possível. Exemplo **inventado**, só para mostrar o formato:

| Critério | Nota | Justificativa |
|---|---|---|
| fidelidade | 1 | Dose diária sustentada por MED-111; a afirmação sobre crianças não aparece em nenhum dos 5 documentos. |
| completude | 2 | Responde quando e como tomar, o que os documentos permitem responder. |
| utilidade | 2 | Orientação direta e prática. |
| rastreabilidade | 1 | Cita MED-111 corretamente, mas atribui a MED-222 um resultado que ele não traz. |

## 6. Regras importantes

- **Não deixe nenhuma célula de nota vazia.** O script trata uma célula vazia como N/A e a exclui da média, sem avisar. Use `N/A` só na rastreabilidade de respostas sem fontes.
- Use apenas `0`, `1`, `2` ou `N/A`. O script para e lista os problemas se encontrar outro valor ou uma nota sem justificativa.
- **Não conversem sobre as notas** antes de os dois terminarem. A concordância entre os avaliadores vai para o relatório.
- Salve **no mesmo arquivo e em CSV**: mesmo nome, mesmas colunas, UTF-8 e vírgula como separador. No LibreOffice, confirme "Usar o formato CSV" ao salvar.

Tempo estimado: de 1 a 2 horas por pessoa (10 perguntas com 5 resumos cada e 20 respostas).

## 7. Depois que os dois terminarem

Na raiz do repositório:

```bash
uv run src/scripts/evaluate_rag.py merge --sheets result/tp2/rag_avaliacao/planilha_avaliador1.csv result/tp2/rag_avaliacao/planilha_avaliador2.csv
uv run src/scripts/check_results.py
```

O primeiro comando:

- grava as notas da **primeira** planilha no `rag_experiment.csv`;
- calcula as médias de cada critério por condição e a concordância entre os avaliadores;
- salva tudo em `result/tp2/rag_evaluation_summary.md`.

O segundo deve terminar com "All standardized result files are complete."

Com o resumo em mãos, sigam os itens do relatório no [`PENDENCIAS.md`](PENDENCIAS.md) (também listados no quadro "O QUE FALTA FAZER" do PDF):

- preencher a tabela da avaliação humana;
- conferir se as notas confirmam os casos da análise de falhas e acrescentar as notas de cada um;
- completar a conclusão.
