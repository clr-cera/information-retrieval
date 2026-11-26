#import "../estilo.typ": *

= Preparação para a defesa

Qualquer integrante pode ser chamado a explicar parte do código ou a prever o efeito de uma mudança. Respostas curtas, com o capítulo onde está o detalhe.

== Perguntas citadas no enunciado

*Mostre como o índice invertido foi construído.* \
`PostingList` em `src/ir/lexical.py`: dicionário `termo → {doc_id: tf}`, mais $n_t$, $|d|$ e o tamanho total. Cada documento é pré-processado e cada termo é inserido atualizando tudo de uma vez (@cap-lexical).

*Explique um cálculo do RRF.* \
Some $1\/(k + "posição")$ em cada sistema em que o documento aparece, com $k = 10$. Em 1º no lexical e 3º no semântico: $1\/11 + 1\/13 = "0,1678"$. Para conferir com dados reais, use a coluna `rank` de `results_lexical.csv` e `results_semantic.csv` (@cap-hibrida).

*Interprete um resultado por consulta.* \
Compare o NDCG\@10 da consulta entre os sistemas no `metrics_per_query.csv` e abra os `results_*.csv` para ver o topo e a coluna `relevance`.

*Justifique a alteração de posições após o reranking.* \
O cross-encoder dá um score novo a cada um dos 50 primeiros, lendo consulta e documento juntos; abaixo do 50º, a ordem não muda. Em "shelf life", o relevante sobe de 34º para 1º (o BM25 vira "shelf-life" em `shelflif`); em "myelopathy", o relevante cai de 5º para 40º, trocado por documentos sobre mieloma (@cap-hibrida).

*Mostre quais documentos foram enviados à LLM.* \
Os 5 primeiros do `results_reranking.csv`, registrados na coluna `context_doc_ids` do `rag_experiment.csv` (vazia na condição A) e no prompt da mesma linha.

*Explique por que uma resposta foi considerada fiel ou não.* \
Compare cada afirmação com os 5 documentos da pergunta (`result/tp2/rag_avaliacao/documentos_por_consulta.md`). Na PLAIN-2850, a resposta sem RAG é contradita pelo MED-4166; a com RAG diz que os documentos não trazem o dado, o que é fiel ao contexto (@cap-rag).

*Altere um parâmetro e preveja o efeito.*

- $b$ de 0,75 para 0: sem normalização por tamanho; muitos empates de score (93 consultas do dev com empate na fronteira do top-10, contra 3); o NDCG\@10 médio quase não muda, porque os documentos têm tamanhos parecidos.
- $k_1$ maior: a frequência do termo pesa mais antes de saturar.
- $k$ do RRF de 10 para 60: o topo de cada sistema perde peso relativo; no dev, NDCG\@10 de 0,3299 para 0,3273.
- Reranking de 50 para 10 documentos: 5 vezes mais rápido, mas relevantes entre a 11ª e a 50ª posição do híbrido não podem mais subir.
- Distância máxima da correção de 2 para 1: transposições deixam de ser corrigidas; acerto de 92% para cerca de 71%.

== Outras perguntas prováveis

#tabela(
  (auto, 1fr),
  [*Pergunta*], [*Resposta curta*],
  [Como a consulta não percorre a coleção?], [O BM25 só visita as posting lists dos termos da consulta (0,16% dos postings em média); $N$ e avgdl vêm do índice. Um teste falha se isso mudar.],
  [E a busca semântica pode percorrer tudo?], [Sim: o enunciado restringe só o índice invertido, e com 3.633 documentos o produto matriz-vetor é rápido.],
  [Por que normalizar os embeddings?], [Com comprimento 1, o produto escalar é o cosseno, e o ranking sai de uma multiplicação de matriz.],
  [Por que não somar BM25 e cosseno?], [Escalas diferentes; o RRF usa só posições, que são comparáveis.],
  [Por que só 50 no reranking?], [Uma passada pelo modelo por par: 50 pares já custam cerca de 4 s por consulta em CPU.],
  [O que é truncamento?], [O bi-encoder lê até 256 tokens (78,8% dos documentos são cortados); o cross-encoder, 512 por par (8,8% dos pares).],
  [Por que BM25 e não o Modelo Vetorial?], [Foi melhor no TP1 e um pouco melhor no dev (0,2906 contra 0,2880); parâmetros interpretáveis; é o baseline lexical do BEIR.],
  [Termo da consulta fora do índice?], [É ignorado. Se todos forem, nada é recuperado (16 consultas do test).],
  [Por que o dicionário da correção não usa stemming?], [Para propor palavras reais, e porque o enunciado exige.],
  [Qual LLM e por que `num_ctx`?], [Qwen3 4B quantizado, local no Ollama, temperatura 0, seed 42. A janela de 16.384 tokens evita que o Ollama corte o prompt com os documentos em silêncio.],
  [Por que avaliar às cegas?], [Quem sabe qual resposta usou RAG tende a favorecê-la; a chave fica separada até o fim.],
  [Quando o RAG falha, de quem é a culpa?], [Siga os estágios no `rag_stage_trace.md`. Na PLAIN-2850, a falha foi da recuperação (paráfrase), não da LLM.],
  [Por que separar dev e test?], [Escolher olhando o test superestima o desempenho; tudo foi escolhido no dev.],
  [Como reproduzir?], [`uv sync` (versões do `uv.lock`), dataset de fonte fixa, config com todas as escolhas, seeds fixas e `run_retrieval_pipeline.py`.],
)
