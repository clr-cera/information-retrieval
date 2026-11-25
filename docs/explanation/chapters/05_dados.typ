#import "../estilo.typ": *

= Dados, configuração e resultados (`ir/data.py`) <cap-dados>

Este módulo tem três partes, vindas de três arquivos antigos: a leitura do NFCorpus (`nfcorpus_loader`), as constantes e a configuração do experimento (`experiment_config`) e a escrita dos arquivos de resultados (`results_io`).

== Parte 1: leitura do NFCorpus

=== Imports

#tabela(
  (auto, 1fr),
  [*Import*], [*Uso no módulo*],
  [`json`], [Ler cada linha do `corpus.jsonl` e do `queries.jsonl`; gravar JSON.],
  [`os`], [`os.environ.get("NFCORPUS_DIR", ...)`: ler a variável de ambiente que muda a pasta do dataset.],
  [`random`], [`random.Random(42).sample(...)`: sortear as 10 consultas do RAG.],
  [`shutil`], [`copyfileobj` (copiar o download para o arquivo) e `copytree` (copiar a pasta extraída).],
  [`tempfile`], [`TemporaryDirectory`: pasta temporária, apagada automaticamente, para extrair o zip.],
  [`urllib.request`], [`urlopen`: fazer o download pela internet.],
  [`zipfile`], [Abrir e extrair o `nfcorpus.zip`.],
  [`dataclass`], [Definir `Document`, `Query`, `Qrel` e `NFCorpusSplit`.],
  [`lru_cache`], [Não ler o mesmo arquivo duas vezes.],
  [`Path`], [Caminhos de arquivos.],
  [`pandas` (dentro de uma função)], [Ler os arquivos parquet do Hugging Face. É importado só dentro da função que o usa, para não exigir o pandas quando o download oficial funciona.],
)

=== Constantes

- `NFCORPUS_URL`: endereço oficial do arquivo do BEIR (servidor da UKP/TU Darmstadt).
- `NFCORPUS_SPLITS = ("train", "dev", "test")`.
- `DOWNLOAD_TIMEOUT_SECONDS = 30`: tempo máximo de espera do servidor.
- `HF_CORPUS_REPO`, `HF_CORPUS_REVISION`, `HF_QRELS_REPO`, `HF_QRELS_REVISION`, `HF_FILES`, `HF_QRELS_URL`: a alternativa no Hugging Face. As *revisões* são identificadores de commit dos repositórios de dados: fixá-las garante que o download seja sempre o mesmo arquivo, mesmo que o repositório mude depois.
- `PROJECT_ROOT`: a raiz do repositório, calculada a partir da posição deste arquivo.
- `DEFAULT_DATA_DIR = PROJECT_ROOT / "data" / "nfcorpus"`.
- `RAG_QUERY_SEED = 42` e `RAG_QUERY_SAMPLE_SIZE = 10`: definidos pelo enunciado.

=== As classes de dados

#funcao("class Document(doc_id: str, title: str, text: str)")[
  Um documento. A propriedade `searchable_text` monta a representação usada por *todos* os sistemas: título e texto, sem espaços nas pontas, descartando partes vazias e unindo com um espaço. É aqui que se cumpre a exigência do enunciado de concatenar `title` e `text`.
]

#funcao("class Query(query_id: str, text: str)")[Uma consulta.]

#funcao("class Qrel(query_id: str, doc_id: str, relevance: int)")[Um julgamento: o documento `doc_id` tem grau `relevance` para a consulta `query_id`.]

#funcao("class NFCorpusSplit(name, documents, queries, qrels)")[
  Um split carregado: o nome, todos os documentos (`dict[str, Document]`), as consultas julgadas no split (`dict[str, Query]`) e os julgamentos (`tuple[Qrel, ...]`). Três propriedades convertem para os formatos que o resto do código usa:
  - `qrels_by_query`: `{query_id: {doc_id: grau}}`. Percorre os julgamentos e usa `setdefault(query_id, {})` para criar o dicionário interno de cada consulta na primeira vez.
  - `document_texts`: `{doc_id: título + texto}`.
  - `query_texts`: `{query_id: texto}`.
]

=== Download

#funcao("def ensure_nfcorpus(data_dir=None, download=True, url=NFCORPUS_URL) -> Path")[
  Garante que o dataset exista no disco e devolve a pasta dele.
  + Escolhe a pasta: a recebida, ou `NFCORPUS_DIR`, ou `data/nfcorpus`.
  + Se os arquivos necessários já existem (`_has_required_files`), devolve a pasta sem fazer nada.
  + Se não existem e `download=False`, lança `FileNotFoundError` (usado pelos testes).
  + Tenta baixar o zip oficial com `_download`. Se der erro de rede (`OSError`, que inclui timeout), imprime um aviso e chama `download_nfcorpus_from_huggingface`.
  + Com o zip baixado, extrai numa pasta temporária e copia o conteúdo para a pasta final. O zip do BEIR tem uma pasta `nfcorpus/` dentro; o código trata os dois casos.
  + Confere de novo se os arquivos existem e grava `SOURCE.txt` com a origem.
]

#funcao("def download_nfcorpus_from_huggingface(root) -> Path")[
  A alternativa quando o servidor oficial está fora do ar. No Hugging Face, o corpus e as consultas estão em *parquet* (formato de tabela compactado) e os qrels em TSV. Para cada parquet, baixa, lê com `pd.read_parquet`, confere se as colunas esperadas existem e grava no mesmo formato JSONL do arquivo oficial (um JSON por linha, valores nulos viram texto vazio). Depois baixa os três TSV de qrels e grava `SOURCE.txt` com os repositórios e as revisões. O resto do código não percebe a diferença.
]

#funcao("def _download(url, destination, timeout=30) -> None")[
  Baixa primeiro para um arquivo `.part` e só renomeia para o nome final quando o download termina. Se qualquer erro acontecer no meio (inclusive o usuário interromper com Ctrl+C, por isso `BaseException`), o arquivo parcial é apagado e o erro é repassado. Assim, um download incompleto nunca parece completo.
]

=== Leitura dos arquivos

#funcao("def load_corpus(path) -> dict[str, Document]")[
  Lê o JSONL linha por linha, ignora linhas vazias e cria um `Document` para cada uma. `record.get("title") or ""` trata título ausente ou nulo como texto vazio. Os identificadores são convertidos para `str`.
]

#funcao("def load_queries(path) -> dict[str, Query]")[Igual, para as consultas.]

#funcao("def load_qrels(path) -> tuple[Qrel, ...]")[
  Lê o TSV (campos separados por tabulação). Os arquivos do BEIR têm uma linha de cabeçalho (`query-id corpus-id score`), mas outras versões não têm: `_is_qrels_header` reconhece o cabeçalho, que é pulado só se for a primeira linha com conteúdo. Linhas com menos de três campos geram erro com o número da linha. O grau é lido com `int(float(...))` para aceitar tanto `2` quanto `2.0`.
]

#funcao("def _load_split_cached(root, split) -> NFCorpusSplit   # com @lru_cache")[
  Monta um split:
  + lê todos os documentos e todas as consultas (com cache);
  + lê os qrels do split;
  + calcula o conjunto de consultas com julgamento (`judged_query_ids`);
  + verifica se todas existem no `queries.jsonl` (senão, erro);
  + mantém *somente* as consultas julgadas. É essa filtragem que faz o test ter 323 consultas, e não as 3.237 do arquivo.
]

#funcao("def load_split(split, data_dir=None, download=True) -> NFCorpusSplit")[
  Função usada pelos scripts. Valida o nome do split, garante o dataset com `ensure_nfcorpus` e devolve o split (com cache).
]

#funcao("def load_all_splits(...) -> dict[str, NFCorpusSplit]")[Carrega os três splits de uma vez (usado pela validação).]

#funcao("def select_rag_query_ids(split, seed=42, sample_size=10) -> list[str]")[
  Reproduz exatamente o código do enunciado para escolher as 10 consultas do RAG: pega os identificadores em ordem alfabética (`sorted`), mantém os que terminam em `?` (perguntas, 42 no test) e sorteia 10 com `random.Random(42).sample`. Criar um gerador próprio com a seed garante o mesmo sorteio em qualquer máquina, sem afetar outros sorteios do programa. O resultado é conferido contra a lista do enunciado.
]

== Parte 2: constantes e configuração do experimento

Constantes de caminho: `DATA_DIR`, `RESULTS_DIR` (`result/tp2`), `EMBEDDINGS_DIR` (`data/embeddings`), `CONFIG_PATH` e um caminho para cada arquivo de resultado (`LEXICAL_RESULTS_PATH`, `METRICS_PER_QUERY_PATH`, `TYPO_EXPERIMENT_PATH`, `RAG_EXPERIMENT_PATH` etc.). `PLOTS_DIR` está definido, mas não é usado por nenhum script do TP2.

Constantes do protocolo, todas definidas pelo enunciado:

#tabela(
  (auto, auto, 1fr),
  [*Constante*], [*Valor*], [*Significado*],
  [`TUNING_SPLIT`, `FINAL_SPLIT`], [`"dev"`, `"test"`], [Onde se ajusta e onde se avalia.],
  [`EVALUATION_CUTOFF`], [10], [O $k$ das métricas.],
  [`RANKING_DEPTH`], [100], [Quantos documentos por consulta vão para os CSVs de ranking.],
  [`FUSION_DEPTH`], [100], [Quantos documentos de cada sistema entram no RRF.],
  [`RERANK_DEPTH`], [50], [Quantos documentos do híbrido o cross-encoder reordena.],
  [`RRF_K_CANDIDATES`], [(10, 60, 100)], [Valores de $k$ testados no RRF.],
  [`RAG_QUERY_IDS`], [10 identificadores], [A amostra fixa do RAG.],
)

#funcao("def default_experiment_config() -> dict")[Monta a configuração inicial: o bloco `protocol` com as constantes acima e o bloco `selected` com tudo `None` (nada escolhido ainda).]

#funcao("def load_experiment_config(path=CONFIG_PATH) -> dict")[Lê o JSON de configuração.]

#funcao("def save_experiment_config(config, path=CONFIG_PATH) -> Path")[Grava a configuração com indentação e acentos legíveis. Usada pelos scripts de ajuste com `--update-config`.]

#funcao("def ensure_experiment_config(path=CONFIG_PATH) -> dict")[Cria o arquivo com os valores padrão se ele não existir e devolve o conteúdo.]

== Parte 3: escrita dos resultados

O enunciado exige arquivos CSV padronizados, independentes de notebooks. As colunas de cada um estão em constantes: `RANKING_COLUMNS`, `METRICS_COLUMNS`, `TYPO_COLUMNS` e `RAG_COLUMNS`. Imports desta parte: `csv`, `json`, os tipos genéricos, `dataclass`, `Path` e `METRIC_KEYS` (de `ir.metrics`).

#funcao("class TypoExperimentRow(...)")[
  Uma linha do experimento de erros: as três versões da consulta, o tipo de erro, os três NDCG\@10, a recuperação e se o erro reduziu o desempenho. `as_csv_dict()` converte para o dicionário que o `DictWriter` grava, usando os nomes de coluna em português pedidos pelo enunciado. Valores `None` viram o texto `"N/A"`.
]

#funcao("class RagExperimentRow(...)")[
  Uma linha do experimento de RAG, criada por `run_rag.py` (com as notas vazias) e por `evaluate_rag.py merge` (com as notas). Além dos campos, tem `__post_init__`, um método que as dataclasses chamam logo depois do construtor: ele valida que a condição é `"A"` ou `"B"` e que cada nota é 0, 1, 2 ou `None`. `context_doc_ids` é gravado como uma lista JSON dentro da célula do CSV.
]

#funcao("def write_ranking_csv(path, rankings, qrels_by_query, depth=100) -> int")[
  Para cada consulta e cada um dos `depth` primeiros documentos, grava `query_id, doc_id, rank, score, relevance`. A posição começa em 1 (`enumerate(..., start=1)`) e a relevância vem dos qrels (0 se o documento não foi julgado). Devolve o número de linhas gravadas.
]

#funcao("def write_metrics_csv(path, model, metrics_by_query) -> int")[Grava as métricas por consulta de um sistema.]

#funcao("def write_combined_metrics_csv(path, model_metrics) -> int")[Grava as métricas por consulta de vários sistemas num só arquivo, com a coluna `model` (`lexical`, `semantic`, `hybrid`, `reranking`). É o `metrics_per_query.csv`.]

#funcao("def write_typo_experiment_csv(path, rows) / write_rag_experiment_csv(path, rows)")[Ambas chamam `_write_dataclass_rows`, que grava cada linha com `as_csv_dict()`. `extrasaction="ignore"` faz o `DictWriter` ignorar chaves que não estejam na lista de colunas.]

#funcao("def _prepare_path(path) -> Path")[Cria a pasta do arquivo, se preciso, e devolve o caminho.]
