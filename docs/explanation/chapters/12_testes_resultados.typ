#import "../estilo.typ": *

= Testes e resultados

== Testes automatizados (`src/tests/`)

Os testes usam o *pytest*: cada função cujo nome começa com `test_` é executada, e cada `assert` dentro dela precisa ser verdadeiro. `pytest.approx` compara números com tolerância para erros de arredondamento; `pytest.raises(Erro)` verifica que um erro é lançado; `tmp_path` é uma pasta temporária criada pelo pytest para cada teste; `monkeypatch` substitui temporariamente uma função ou atributo.

Para rodar: `uv run pytest` (74 testes). Os testes não dependem de internet: os de dados criam um dataset artificial pequeno em `tmp_path`, e os de reranking usam funções de score falsas em vez do modelo. O único teste que usa o NFCorpus real é pulado se o dataset não estiver em `data/` (`@pytest.mark.skipif`).

#tabela(
  (auto, 1fr),
  [*Arquivo*], [*O que verifica*],
  [`test_metrics.py`], [P\@k, R\@k, AP\@k (truncada em 10, mas dividindo pelo total de relevantes), NDCG\@k (ganho linear e ideal com todos os julgamentos), Hit\@k, métricas zeradas sem relevantes, erro quando falta uma consulta, média sobre consultas e, principalmente, igualdade com o `ir_measures` em casos aleatórios.],
  [`test_data.py`], [Representação título + texto; filtragem das consultas sem julgamento; leitura de qrels com e sem cabeçalho; sorteio do RAG determinístico e igual ao enunciado (dataset real); erro quando o dataset falta e o download está desligado; configuração padrão e leitura e gravação do config; os quatro escritores de CSV (limite de profundidade, coluna de relevância, conteúdo das linhas de erro e de RAG, validação das notas do RAG).],
  [`test_lexical.py`], [Cada etapa do pré-processamento e as quatro opções do pipeline; o índice (postings, frequências, $n_t$, tamanhos, vocabulário, estatísticas globais e cópias nos métodos `get_all_*`); o BM25 (só devolve documentos com algum termo, score igual à fórmula calculada à mão, *a consulta não copia as estatísticas da coleção*); a avaliação; e a correção ortográfica (k-gramas com marcadores, Jaccard, Levenshtein, dicionário sem stemming, correção de erros, variantes dos quatro tipos e erros sempre fora do vocabulário).],
  [`test_neural.py`], [Ordenação por produto escalar; RRF (fórmula, documentos ausentes de um ranking, profundidade, validações); avaliação de rankings; reranking (separação topo/resto, só o topo é reordenado, o resto mantém a ordem, número de scores igual ao de candidatos).],
)

O teste `test_bm25_query_does_not_copy_collection_statistics` merece destaque: ele substitui `get_all_document_lengths` e `get_all_document_frequencies` por funções que geram erro e executa uma consulta. Se o BM25 voltar a copiar as estatísticas da coleção a cada consulta (o que violaria o enunciado), o teste falha.

== Resultados no conjunto test

Configuração final: pré-processamento com stopwords e stemming; BM25 com $k_1 = "1,2"$ e $b = "0,75"$; `all-MiniLM-L6-v2`; RRF com $k = 10$; `ms-marco-MiniLM-L6-v2` nos 50 primeiros.

#tabela(
  (auto, auto, auto, auto, auto, auto),
  [*Sistema*], [*P\@10*], [*R\@10*], [*MAP\@10*], [*NDCG\@10*], [*Tempo por consulta*],
  [Lexical (BM25)], [0,2307], [0,1411], [0,1109], [0,3124], [~1 ms],
  [Semântico], [0,2433], [0,1550], [0,1108], [0,3167], [~0,16 s],
  [Híbrido (RRF)], [0,2557], [0,1657], [0,1259], [0,3440], [soma dos dois],
  [Híbrido + reranking], [0,2505], [0,1679], [0,1382], [*0,3557*], [+ ~4 s],
)

Leitura dos números:

- Lexical e semântico têm desempenho médio parecido, mas acertam consultas diferentes; por isso a fusão melhora as duas (de 0,31 para 0,34 de NDCG\@10).
- O reranking melhora o NDCG\@10 e o MAP\@10, que valorizam a *ordem* dos relevantes no topo, mas não o P\@10. Ele reorganiza os 50 primeiros, colocando os mais relevantes mais acima, sem necessariamente trazer mais relevantes para o top-10.
- O ganho tem custo: o reranking multiplica o tempo por consulta por mais de 20.
- Os valores de R\@10 são baixos para todos: as consultas têm em média 38 relevantes, e um top-10 só consegue mostrar parte deles.

Experimento de erros (10 consultas, sistema lexical): NDCG\@10 médio de 0,4706 na consulta original, 0,1625 com erro e 0,4706 após a correção; as 10 correções recuperaram a palavra original.

== O que ainda falta: RAG

A etapa de RAG ainda não foi implementada. O que já existe:

- `select_rag_query_ids` reproduz a amostra fixa de 10 consultas (verificada contra o enunciado);
- `RagExperimentRow` e `write_rag_experiment_csv` definem o formato do `rag_experiment.csv`;
- o config tem os campos `llm`, `llm_temperature`, `llm_max_tokens` e `rag_language`, ainda vazios.

O plano do enunciado: para cada uma das 10 consultas, gerar uma resposta *sem RAG* (só a pergunta) e *com RAG* (a pergunta e os 5 primeiros documentos do reranking, com identificadores); medir P\@5, R\@5 e Hit\@5 dos documentos enviados; e avaliar as respostas com notas de 0 a 2 em fidelidade, completude, utilidade e rastreabilidade.
