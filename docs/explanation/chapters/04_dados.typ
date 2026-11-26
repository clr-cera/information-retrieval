#import "../estilo.typ": *

= Dados, configuração e resultados (`ir/data.py`) <cap-dados>

O módulo é a camada de entrada e saída do projeto. Tem três partes.

== Leitura do NFCorpus

- *Download* (`ensure_nfcorpus`): se os arquivos já estão em `data/nfcorpus/` (ou na pasta da variável `NFCORPUS_DIR`), não faz nada. Senão, baixa o zip oficial do BEIR; se o servidor falhar, usa uma cópia no Hugging Face com *revisões fixadas* (o mesmo arquivo sempre, mesmo que o repositório mude) e converte para o formato oficial. O download vai para um arquivo `.part`, renomeado só no fim, para que um download interrompido nunca pareça completo. A origem fica em `SOURCE.txt`.
- *Classes de dados*: `Document`, `Query`, `Qrel` e `NFCorpusSplit` (dataclasses imutáveis). `Document.searchable_text` junta título e texto: é a representação usada por *todos* os sistemas, como pede o enunciado. `NFCorpusSplit` oferece os formatos que o resto do código usa: `qrels_by_query` (`{consulta: {doc: grau}}`), `document_texts` e `query_texts`.
- *Carregamento* (`load_split`): lê corpus, consultas e qrels do split (aceitando TSV com ou sem cabeçalho) e mantém *só as consultas julgadas* naquele split — é isso que faz o test ter 323 consultas, e não 3.237. Um cache (`lru_cache`) evita ler o corpus mais de uma vez por execução.
- *Amostra do RAG* (`select_rag_query_ids`): reproduz o código do enunciado — identificadores em ordem alfabética, só os que terminam em `?`, sorteio de 10 com `random.Random(42)`. O resultado é conferido contra a lista do enunciado.

== Constantes e configuração

Caminhos (`RESULTS_DIR = results`, `EMBEDDINGS_DIR`, `CONFIG_PATH` e um caminho por arquivo de resultado) e as constantes do protocolo, todas definidas pelo enunciado:

#tabela(
  (auto, auto, 1fr),
  [*Constante*], [*Valor*], [*Significado*],
  [`TUNING_SPLIT`, `FINAL_SPLIT`], [dev, test], [Onde se ajusta e onde se avalia.],
  [`EVALUATION_CUTOFF`], [10], [O $k$ das métricas.],
  [`RANKING_DEPTH`], [100], [Documentos por consulta nos CSVs de ranking.],
  [`FUSION_DEPTH`], [100], [Documentos de cada sistema que entram no RRF.],
  [`RERANK_DEPTH`], [50], [Documentos do híbrido que o cross-encoder reordena.],
  [`RRF_K_CANDIDATES`], [10, 60, 100], [Valores de $k$ testados no RRF.],
)

Funções simples leem, gravam e criam (com valores padrão) o `tp2_experiment.json`.

== Escrita dos resultados

O enunciado exige CSVs com colunas padronizadas; as colunas de cada arquivo estão em constantes (`RANKING_COLUMNS`, `METRICS_COLUMNS`, `TYPO_COLUMNS`, `RAG_COLUMNS`). Há um escritor para cada tipo:

- *rankings* (`results_*.csv`): `query_id, doc_id, rank, score, relevance`, com a relevância vinda dos qrels (0 se não julgado);
- *métricas por consulta*: um sistema por arquivo ou os quatro juntos, com a coluna `model` (é o `metrics_per_query.csv`);
- *erros ortográficos* e *RAG*: cada linha é uma dataclass (`TypoExperimentRow`, `RagExperimentRow`) que se converte para as colunas em português do enunciado. `RagExperimentRow` valida a condição (A ou B) e as notas (0, 1, 2 ou vazio) ao ser criada; `None` é gravado como `N/A`.
