#import "../estilo.typ": *

= Testes e resultados

== Testes automatizados (`src/tests/`)

`uv run pytest` roda 77 testes, sem internet: os de dados criam um dataset artificial numa pasta temporária, e os de reranking usam funções de score falsas. O único teste com o NFCorpus real é pulado se o dataset não estiver em `data/`.

#tabela(
  (auto, 1fr),
  [*Arquivo*], [*O que verifica*],
  [`test_metrics.py`], [Cada métrica, casos sem relevantes, erro quando falta uma consulta e igualdade com o `ir_measures` em casos aleatórios.],
  [`test_data.py`], [Título + texto, filtragem das consultas sem julgamento, qrels com e sem cabeçalho, sorteio do RAG, config e os escritores de CSV.],
  [`test_lexical.py`], [Pré-processamento, índice, BM25 (score igual à fórmula, só documentos com algum termo, *a consulta não copia as estatísticas da coleção*) e correção ortográfica.],
  [`test_neural.py`], [Ordenação por produto escalar, RRF e reranking (só o topo é reordenado; o resto mantém a ordem).],
  [`test_rag.py`], [Conteúdo dos prompts das duas condições, sem chamar a LLM.],
)

Destaque: `test_bm25_query_does_not_copy_collection_statistics` troca os métodos que copiam as estatísticas da coleção por funções que geram erro e executa uma consulta. Se o BM25 voltar a percorrer a coleção a cada consulta (o que o enunciado proíbe), o teste falha.

== Resultados no test

Configuração final: stopwords + stemming; BM25 com $k_1 = "1,2"$ e $b = "0,75"$; `all-MiniLM-L6-v2`; RRF com $k = 10$; `ms-marco-MiniLM-L6-v2` nos 50 primeiros.

#tabela(
  (auto, auto, auto, auto, auto, auto),
  [*Sistema*], [*P\@10*], [*R\@10*], [*MAP\@10*], [*NDCG\@10*], [*Tempo por consulta*],
  [Lexical (BM25)], [0,2307], [0,1411], [0,1109], [0,3124], [~1 ms],
  [Semântico], [0,2433], [0,1550], [0,1108], [0,3167], [~0,16 s],
  [Híbrido (RRF)], [0,2557], [0,1657], [0,1259], [0,3440], [soma dos dois],
  [Híbrido + reranking], [0,2505], [0,1679], [0,1382], [*0,3557*], [+ ~4 s],
)

- Lexical e semântico têm média parecida, mas acertam consultas diferentes; por isso a fusão melhora os dois.
- O reranking melhora NDCG\@10 e MAP\@10, que valorizam a *ordem* no topo, mas não o P\@10: ele reorganiza os 50 primeiros sem necessariamente trazer mais relevantes ao top-10. E multiplica o tempo por consulta por mais de 20.
- O R\@10 é baixo para todos porque as consultas têm cerca de 38 relevantes.

Erros ortográficos: NDCG\@10 de 0,4706 → 0,1625 → 0,4706 (original, com erro, corrigida). RAG: P\@5 = 0,44, Hit\@5 = 0,90, citações sempre entre os documentos enviados.

