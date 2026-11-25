#import "../estilo.typ": *

= Preparação para a defesa

O enunciado avisa que qualquer integrante pode ser chamado a explicar parte do código ou a prever o efeito de uma mudança. Abaixo estão as perguntas citadas no enunciado e outras prováveis, com a resposta curta e onde está o detalhe.

== Perguntas citadas no enunciado

*Mostre como o índice invertido foi construído.* \
`PostingList` (`src/ir/lexical.py`): dicionário `termo → {doc_id: tf}`, mais `document_frequencies`, `document_lengths` e `total_length`. `add_documents` pré-processa cada documento e chama `_add_posting` para cada termo, que atualiza tudo de uma vez (@cap-bm25).

*Explique um cálculo do RRF.* \
Some $1\/(k + "posição")$ em cada sistema em que o documento aparece (posição a partir de 1; $k = 10$). Um documento em 1º no lexical e 3º no semântico: $1\/11 + 1\/13 = "0,1678"$. Ausente de um sistema: só a parcela do outro (@cap-hibrida). Para conferir com dados reais, use as colunas `rank` dos `results_lexical.csv` e `results_semantic.csv`.

*Interprete um resultado por consulta.* \
Use o `metrics_per_query.csv`: compare o NDCG\@10 de uma consulta entre os sistemas e abra os `results_*.csv` para ver quais documentos estão no topo e a coluna `relevance`.

*Justifique a alteração de posições após o reranking.* \
O cross-encoder lê consulta e documento juntos e dá um score novo a cada um dos 50 primeiros; a nova ordem é por esse score. Documentos abaixo do 50º não mudam de ordem relativa (@cap-hibrida).

*Mostre quais documentos foram enviados à LLM.* \
Os 5 primeiros do ranking com reranking para cada consulta da amostra; vão para a coluna `context_doc_ids` do `rag_experiment.csv` (etapa ainda pendente).

*Altere um parâmetro e preveja o efeito.* Alguns exemplos:

- $b$ de 0,75 para 0: desliga a normalização por tamanho; documentos longos deixam de ser penalizados e os empates de score aumentam muito (no dev, com $k_1 = "2,0"$ e $b = 0$, 93 consultas tinham empate na fronteira do top-10, contra 3 com os valores usuais). O NDCG\@10 médio quase não muda no NFCorpus, porque os documentos têm tamanhos parecidos.
- $k_1$ maior: a frequência do termo pesa mais antes de saturar; favorece documentos que repetem os termos da consulta.
- $k$ do RRF de 10 para 60: as posições ficam mais parecidas entre si; o topo de cada sistema perde peso relativo. No dev, o NDCG\@10 caiu de 0,3299 para 0,3273.
- Profundidade do reranking de 50 para 10: mais rápido (5 vezes menos pares), mas o cross-encoder só pode reordenar dentro do top-10, então documentos relevantes entre as posições 11 e 50 do híbrido não podem subir.
- Distância máxima da correção de 2 para 1: as trocas de ordem de letras deixam de ser corrigidas (custam 2); no dev, o acerto cai de 92% para cerca de 71%.

== Outras perguntas prováveis

*Por que o BM25 e não o Modelo Vetorial?* \
O BM25 foi melhor no TP1 (Cranfield) e um pouco melhor na média no dev do NFCorpus (0,2906 contra 0,2880), tem parâmetros com interpretação clara e é o baseline lexical do BEIR.

*Como vocês garantem que a consulta não percorre toda a coleção?* \
O BM25 só percorre as posting lists dos termos da consulta; $N$ e $"avgdl"$ vêm do índice em tempo constante. Há um teste que falha se a consulta copiar as estatísticas da coleção. Em média, cada consulta visita 0,16% dos postings.

*Por que a busca semântica pode percorrer todos os documentos?* \
O enunciado restringe só o índice invertido; com 3.633 documentos, o produto matriz-vetor é rápido.

*Por que normalizar os embeddings?* \
Com vetores de comprimento 1, o produto escalar é igual ao cosseno, e o ranking pode ser calculado com uma única multiplicação de matriz.

*O que é truncamento e quanto ele afeta?* \
O bi-encoder lê no máximo 256 tokens; 78,8% dos documentos passam disso e são cortados, e 32% dos tokens da coleção ficam de fora. O cross-encoder lê até 512 tokens por par; 8,8% dos pares são cortados.

*Por que não somar os scores do BM25 e do cosseno?* \
Estão em escalas diferentes (o BM25 não tem limite; o cosseno fica entre −1 e 1). O RRF usa só as posições, que são comparáveis.

*Por que o reranking só reordena 50 documentos?* \
O cross-encoder precisa de uma passada pelo modelo para cada par consulta–documento: com 50 pares, já leva cerca de 4 s por consulta em CPU.

*Por que usar o dev e o test separadamente?* \
Escolher configurações olhando o test superestima o desempenho. Tudo foi escolhido no dev; o test só mede a configuração final.

*Por que o dicionário da correção não usa stemming?* \
A correção precisa propor palavras reais. Além disso, o enunciado exige.

*O que acontece com um termo da consulta que não está no índice?* \
É ignorado pelo BM25. Se todos forem desconhecidos, nenhum documento é recuperado (16 consultas do test).

*Como os resultados podem ser reproduzidos?* \
`uv sync` instala as mesmas versões (`uv.lock`); o dataset vem de uma fonte fixa (com revisões fixadas no Hugging Face); o config registra todas as escolhas; os sorteios usam seed fixa; e `run_retrieval_pipeline.py` regenera todos os CSVs.

== Glossário

#tabela(
  (auto, 1fr),
  [*Termo*], [*Significado*],
  [qrels], [Julgamentos de relevância: (consulta, documento, grau).],
  [split], [Divisão das consultas: train, dev ou test.],
  [termo], [Unidade do índice após o pré-processamento (por exemplo, `vitamin`, `fall`).],
  [posting list], [Lista dos documentos que contêm um termo, com a frequência em cada um.],
  [$t f$], [Frequência de um termo em um documento.],
  [$n_t$ / df], [Número de documentos que contêm o termo.],
  [IDF], [Peso que favorece termos raros.],
  [avgdl], [Tamanho médio dos documentos, em termos.],
  [embedding], [Vetor de números que representa o significado de um texto.],
  [bi-encoder], [Modelo que gera um vetor por texto, de forma independente.],
  [cross-encoder], [Modelo que lê consulta e documento juntos e dá um score ao par.],
  [token (subpalavra)], [Unidade de entrada dos modelos neurais; palavras raras viram vários tokens.],
  [truncamento], [Corte do texto que passa do tamanho máximo do modelo.],
  [RRF], [Fusão de rankings pela soma de $1\/(k + "posição")$.],
  [reranking], [Reordenar os primeiros resultados com um modelo mais preciso.],
  [RAG], [Gerar uma resposta com um modelo de linguagem a partir de documentos recuperados.],
)
