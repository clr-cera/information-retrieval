#import "../estilo.typ": *

= Os scripts (`src/scripts/`) <cap-scripts>

Cada script é um programa independente, executado com `uv run src/scripts/<nome>.py`. Todos seguem o mesmo esquema: ler as opções da linha de comando (`argparse`), ler o config, carregar o split, chamar funções da biblioteca `ir`, gravar os resultados em `result/tp2/` e imprimir um resumo. A função principal chama-se `main()` e só é executada quando o arquivo é rodado diretamente, por causa do bloco:

```python
if __name__ == "__main__":
    main()
```

== Ordem de execução

```
1. validate_experiment.py                 confere dataset, amostra do RAG e métricas
2. tune_lexical.py      (dev)             pipeline de pré-processamento, k1 e b
   tune_typo.py         (dev)             limiares da correção ortográfica
   tune_semantic.py     (dev)             modelo de embeddings
   tune_hybrid.py       (dev)             k do RRF          (depende do lexical e do semântico)
   tune_reranker.py     (dev)             modelo do reranker (depende do híbrido)
3. run_retrieval_pipeline.py (test)       lexical, semântico, híbrido e reranking
   run_typo.py          (test)            experimento de erros
   analyze_typo.py, analyze_lexical_vs_semantic.py, analyze_reranking.py   análises
4. run_rag.py           (test)            respostas sem RAG e com RAG (precisa do Ollama)
   evaluate_rag.py prepare                métricas do contexto, rastreamento e planilhas cegas
   (avaliação humana)
   evaluate_rag.py merge --sheets ...     junta as notas
5. check_results.py                       confere os arquivos exigidos pelo enunciado
```

Os scripts de ajuste só gravam a escolha no config com `--update-config`. A ordem importa: o ajuste do RRF usa o lexical e o semântico já escolhidos, e o do reranker usa o híbrido.

== `validate_experiment.py`

Não tem opções. Ele:
+ carrega os três splits e imprime documentos, consultas e julgamentos de cada um;
+ refaz o sorteio das consultas do RAG e confere que é igual à lista do enunciado (senão, para com erro);
+ monta, para cada consulta do test, um ranking artificial com todos os documentos julgados e mais 30 não julgados, embaralhados com seed 0. Os scores são decrescentes na ordem do ranking, porque o `ir_measures` ordena por score;
+ calcula P\@10, R\@10, AP\@10 e NDCG\@10 com as funções do projeto e com o `ir_measures` (`ir_measures.calc_aggregate`), e confere que a diferença é menor que $10^(-12)$.

== `tune_lexical.py`

Opções: `--split` (padrão `dev`) e `--update-config`. Para cada uma das 4 opções de pré-processamento, constrói o índice *uma vez* e avalia as 9 combinações de $k_1 in {"0,5"; "1,2"; "2,0"}$ e $b in {0; "0,75"; "1,0"}$ com `evaluate_bm25` (o mesmo índice gera vários modelos). Cada resultado vira um `TuningRow` (dataclass com o pipeline, $k_1$, $b$, as 4 métricas e as estatísticas do índice), e todos vão para `lexical_tuning_dev.csv`. A melhor linha é a de maior NDCG\@10 (desempate por AP\@10 e P\@10). Com `--update-config`, grava pipeline, modelo BM25, $k_1$ e $b$ no config — *não* usar, porque o grupo fixou os valores usuais à mão.

== `tune_typo.py`

Opções: `--split` (`dev`), `--samples` (200), `--seed` (42) e `--update-config`.
+ Monta o dicionário da coleção.
+ `build_evaluation_pairs`: percorre as consultas do dev em ordem de identificador e gera um erro em cada uma com `inject_query_error`, alternando o tipo pela posição (`ERROR_TYPES[index % 4]`) e excluindo stopwords, até ter 200 pares (termo com erro, termo original).
+ Para cada configuração da grade $k in {2, 3}$ × Jaccard $in {"0,2"; "0,3"; "0,4"; "0,5"}$ × distância $in {1, 2, 3}$, cria um `SpellingCorrector` e corrige os 200 termos. Mede a *acurácia* (fração corrigida exatamente) e a distância média entre a correção e o original.
+ Grava `typo_tuning_dev.csv` e escolhe a de maior acurácia; em empate, a de menor distância média e, depois, a com menores $k$, distância máxima e limiar.

== `tune_semantic.py`

Opções: `--split` (`dev`) e `--update-config`. Para cada modelo da tupla `SEMANTIC_MODELS` (`all-MiniLM-L6-v2` e `multi-qa-MiniLM-L6-cos-v1`), cria o `SemanticIndex` (gerando ou lendo os embeddings) e roda `evaluate_semantic`. Um modelo que falhe ao carregar (por exemplo, sem internet) é pulado com aviso, graças ao `try/except`. Grava `semantic_tuning_dev.csv` com as métricas, os tempos e o número de documentos truncados, e escolhe o de maior NDCG\@10.

== `tune_hybrid.py`

Opções: `--split` (`dev`) e `--update-config`. Roda o lexical e o semântico com as escolhas do config e, para cada $k$ de `RRF_K_CANDIDATES` (10, 60, 100), funde os rankings e mede as métricas. Grava `hybrid_tuning_dev.csv` e escolhe o $k$ de maior NDCG\@10, como manda o enunciado.

== `tune_reranker.py`

Opções: `--split` (`dev`) e `--update-config`. Monta o híbrido com o $k$ do config e, para cada modelo de `RERANKER_MODELS` (`ms-marco-MiniLM-L6-v2` e `ms-marco-TinyBERT-L2-v2`), aplica o reranking aos 50 primeiros. Grava `reranker_tuning_dev.csv` (métricas, tempo médio e pares truncados) e escolhe o de maior NDCG\@10. Com `--update-config`, também marca `status` como `retrieval_tuned`.

== `run_retrieval_pipeline.py`

A avaliação final. Opção: `--split` (padrão `test`).
+ `output_paths(split)` define onde gravar: no test, os caminhos oficiais em `result/tp2/`; em outro split, uma subpasta (`result/tp2/dev/`), para nunca sobrescrever os resultados oficiais.
+ Roda, com as escolhas do config: o lexical (`build_lexical_run`), o semântico (`build_semantic_run`), o híbrido (`build_hybrid_rankings` + `evaluate_rankings`) e o reranking (`CrossEncoderReranker` + `evaluate_reranker`).
+ Grava os quatro `results_*.csv` (100 primeiros por consulta), o `metrics_per_query.csv` com os quatro sistemas, `lexical_stats.json` (estatísticas do índice e tempo por consulta), `semantic_stats.json`, `reranking_stats.json` e `retrieval_summary.json` (config usada e médias).
+ Imprime as médias e os tempos.

Leva cerca de 25 minutos em CPU, quase todo no reranking.

== `run_lexical.py`

Roda só o BM25. Opções: `--split` (padrão `test`), `--pipeline`, `--k1` e `--b` (para sobrescrever o config) e `--rankings-output`, `--metrics-output` e `--stats-output` (para gravar em outros lugares).

#atencao[
  Sem `--metrics-output`, ele grava o `metrics_per_query.csv` oficial *só com o modelo lexical*, apagando os outros três sistemas. Para medir só o lexical, redirecione as saídas.
]

== `run_typo.py`

O experimento de erros. Opções: `--split` (`test`), `--queries` (10) e `--seed` (42).
+ Lê do config o pipeline, $k_1$, $b$ e os limiares da correção.
+ Constrói o índice, roda o BM25 em todas as consultas (para saber o NDCG\@10 original) e monta o dicionário e o corretor.
+ Seleciona as consultas com NDCG\@10 original maior que zero, em ordem de identificador.
+ Para cada uma, até ter 10 linhas:
  - cria um gerador com seed `42 + número de linhas já feitas`;
  - `choose_injected_error` tenta o tipo da vez (`número de linhas % 4`) e, se não for possível, os seguintes;
  - corrige a consulta com erro;
  - calcula o NDCG\@10 das consultas com erro e corrigida (`ndcg_for_query`);
  - calcula a recuperação, se o erro reduziu o NDCG\@10, ou marca que não reduziu.
+ Grava `typo_experiment.csv` e `typo_experiment_summary.json` (médias, recuperação média e número de correções exatas).

== `analyze_typo.py`

Lê o `typo_experiment.csv` e confere as regras do enunciado em cada consulta:
- NDCG\@10 original maior que zero;
- exatamente um termo alterado (`find_changed_tokens` compara as listas de tokens);
- termo com erro fora do dicionário e termo original dentro;
- nenhuma correção indevida em outros termos.

Monta a tabela por consulta, as médias e a contagem por tipo. Para as consultas em que o erro não reduziu o NDCG\@10, mostra o número de documentos de cada termo e o top-5 das duas versões, com os graus de relevância. Grava tudo em `typo_analysis.md` e encerra com erro se alguma regra falhar.


== `analyze_lexical_vs_semantic.py`

Análise por consulta do requisito 7. Lê o `metrics_per_query.csv` e os rankings lexical e semântico (`read_ndcg_by_query`, `read_rankings`), calcula a diferença de NDCG\@10 (semântico − lexical) e seleciona as 3 consultas de cada lado (`select_queries`, com desempate pelo identificador). Para cada uma, `describe_query` reúne a evidência:

- os termos da consulta no índice e em quantos documentos cada um aparece;
- quantos relevantes têm algum termo da consulta, isto é, quantos o BM25 consegue alcançar;
- para cada documento do top-5 de cada sistema: o score, o grau, os termos da consulta que ele contém (com o $t f$), o número de tokens (marcando se o bi-encoder o trunca), a posição no outro sistema e o título.

O tokenizador do bi-encoder é carregado só para contar tokens. Saída: `lexical_vs_semantic_analysis.md`.

== `analyze_reranking.py`

Análise do requisito 10. Compara o NDCG\@10 do híbrido e do reranking por consulta e escolhe (`select_cases`): os 2 maiores ganhos, 1 caso de pouca ou nenhuma alteração (a menor diferença em módulo entre as consultas com NDCG\@10 do híbrido maior que zero) e a maior piora. Para cada caso, `describe_case` lista os documentos do top-10 após o reranking e os relevantes que saíram dele, com o grau, a posição antes e depois, o score do cross-encoder, se o par consulta + documento passa de 512 tokens e o título. Saída: `reranking_analysis.md`.

== `run_rag.py` e `evaluate_rag.py`

Descritos no @cap-rag.

== `check_results.py`

Verifica os 7 arquivos exigidos pelo enunciado:

- rankings: as colunas obrigatórias, no máximo 100 documentos por consulta, posições 1, 2, 3... sem buracos, todas as consultas presentes (o lexical pode ter rankings vazios) e a coluna `relevance` igual aos qrels;
- `metrics_per_query.csv`: os 4 sistemas com todas as consultas e a média de `AP10` igual ao MAP\@10 do `retrieval_summary.json`;
- `typo_experiment.csv`: 10 consultas;
- `rag_experiment.csv`: 20 linhas e as notas humanas preenchidas.

Lista os problemas encontrados e termina com erro se houver algum. Hoje, o único problema é a falta das notas humanas.
