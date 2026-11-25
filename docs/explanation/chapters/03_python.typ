#import "../estilo.typ": *

= Recursos de Python usados no código

Este capítulo explica, uma vez só, os recursos da linguagem e da biblioteca padrão que aparecem em vários arquivos. Nos capítulos seguintes, eles são citados sem repetir a explicação.

== `from __future__ import annotations`

Aparece no topo de quase todos os arquivos. Faz o Python guardar as anotações de tipo (como `-> dict[str, float]`) como texto, sem avaliá-las na hora em que a função é definida. Na prática, permite usar anotações modernas e referências a classes definidas mais abaixo no mesmo arquivo. Não muda o comportamento do programa.

== Anotações de tipo

As assinaturas indicam o tipo de cada parâmetro e do retorno, por exemplo:

```python
def ndcg_at_k(ranked_doc_ids: Sequence[str], qrels: Mapping[str, int], k: int) -> float:
```

- `str | None`: o valor é um texto ou `None`.
- `dict[str, int]`: dicionário de texto para inteiro.
- `tuple[Qrel, ...]`: tupla de qualquer tamanho só com objetos `Qrel`.
- `Mapping`, `Sequence`, `Iterable` e `Callable` (de `collections.abc`) são tipos *genéricos*: `Mapping` aceita qualquer coisa que funcione como dicionário só para leitura; `Sequence`, qualquer coisa indexável como lista ou tupla; `Iterable`, qualquer coisa que dê para percorrer com `for`; `Callable[[A], B]`, uma função que recebe `A` e devolve `B`.

O Python *não verifica* esses tipos ao executar: eles servem de documentação e para ferramentas de análise do editor.

== `@dataclass(frozen=True)`

Uma *dataclass* é uma classe que só guarda dados. O decorador gera automaticamente o construtor, a comparação (`==`) e a representação em texto a partir dos campos declarados:

```python
@dataclass(frozen=True)
class Qrel:
    query_id: str
    doc_id: str
    relevance: int

qrel = Qrel(query_id="PLAIN-1", doc_id="MED-10", relevance=2)
```

Com `frozen=True`, os objetos são *imutáveis*: tentar fazer `qrel.relevance = 1` gera erro. O projeto usa isso para que resultados (`LexicalRun`, `SemanticRun`, `IndexStats`) e registros (`Document`, `Query`) não sejam alterados por engano depois de criados.

== `@property`

Transforma um método em algo que se lê como um atributo, sem parênteses. Em `NFCorpusSplit`, `split.document_texts` executa o método que monta o dicionário `{doc_id: título + texto}` toda vez que é acessado. Em `LexicalRun`, `run.average_query_time_seconds` calcula a média dos tempos na hora.

== `Enum`

Define um conjunto fechado de opções com nome. `PipelineOptions` (no @cap-preproc) é um `Enum` com as quatro combinações de pré-processamento. `PipelineOptions["WithStopRemovalWithStemming"]` obtém a opção a partir do nome guardado no arquivo de configuração, e `str(opção)` devolve o nome.

== `functools.lru_cache`

Decorador que guarda o resultado de uma função para cada combinação de argumentos. Se a função é chamada de novo com os mesmos argumentos, o resultado guardado é devolvido sem executá-la. Em `ir/data.py`, ele evita ler o `corpus.jsonl` (3.633 documentos) várias vezes na mesma execução: `load_all_splits` carrega os três splits, mas o corpus é lido uma única vez. `maxsize=8` limita quantos resultados ficam guardados.

== `time.perf_counter()`

Devolve um relógio de alta precisão, em segundos. O padrão usado para medir tempos é:

```python
start = perf_counter()
... trabalho ...
elapsed = perf_counter() - start
```

Só a diferença entre duas leituras tem significado. É assim que o projeto mede o tempo de construção do índice, o tempo de cada consulta e o tempo de gerar embeddings.

== `pathlib.Path`

Representa caminhos de arquivos. O operador `/` junta partes (`PROJECT_ROOT / "data" / "nfcorpus"`), e há métodos como `.exists()`, `.is_file()`, `.mkdir(parents=True, exist_ok=True)` (cria a pasta e as pastas acima, sem erro se já existir), `.read_text()` e `.write_text()`. `Path(__file__).resolve().parents[2]` pega o caminho absoluto do arquivo atual e sobe dois níveis acima da pasta dele: de `src/ir/data.py` chega à raiz do repositório.

== `collections.Counter`

Um dicionário que conta ocorrências. `Counter(["a", "b", "a"])` vale `{"a": 2, "b": 1}`, e `contador.update(lista)` soma as contagens de uma nova lista. É usado para obter a frequência de cada termo em um documento e no dicionário da correção ortográfica.

== Compreensões e geradores

O código usa muito as formas compactas de criar listas, dicionários e conjuntos:

```python
[term for term in query_result if term in postings]            # lista filtrada
{doc_id: doc.searchable_text for doc_id, doc in docs.items()}   # dicionário
sum(length > 256 for length in lengths)                          # gerador: conta quantos são True
```

Na última linha, `length > 256` vale `True` ou `False`, que o Python soma como 1 ou 0: o resultado é a quantidade de elementos que satisfazem a condição.

== Ordenação com chave

`sorted(itens, key=função)` ordena pelos valores que a função devolve. Quando a chave é uma tupla, a ordenação compara o primeiro elemento e, em caso de empate, o segundo, e assim por diante:

```python
sorted(scores.items(), key=lambda item: (-item[1], item[0]))
```

Aqui, `-item[1]` ordena pelo score de forma decrescente (o sinal negativo inverte a ordem), e `item[0]` desempata pelo identificador do documento, em ordem alfabética. Isso torna o ranking *determinístico*: a mesma entrada sempre produz a mesma ordem.

Quando se usa `reverse=True` sem desempate explícito (como no BM25), elementos com a mesma chave mantêm a ordem em que estavam antes da ordenação, porque a ordenação do Python é *estável*.

== `csv`, `json` e `argparse`

- `csv.DictWriter(arquivo, fieldnames=colunas)` escreve um CSV a partir de dicionários: `writeheader()` grava a linha de cabeçalho e `writerow(dicionário)` grava uma linha. O `newline=""` ao abrir o arquivo evita linhas em branco extras no Windows.
- `json.load`/`json.dump` leem e gravam JSON; `json.loads`/`json.dumps` fazem o mesmo com textos. `ensure_ascii=False` mantém acentos legíveis no arquivo.
- `argparse.ArgumentParser` lê as opções da linha de comando dos scripts: `parser.add_argument("--split", default="test")` cria a opção `--split`, e `args = parser.parse_args()` devolve os valores, acessados como `args.split`. `action="store_true"` cria uma opção sem valor, que vale `True` se for passada (como `--update-config`).

== NumPy e o operador `@`

`numpy` é a biblioteca de vetores e matrizes. Na busca semântica, os embeddings dos documentos formam uma matriz de 3.633 linhas por 384 colunas, e o embedding da consulta é um vetor de 384 posições. A expressão `matriz @ vetor` faz o *produto matriz-vetor*: o resultado tem 3.633 posições, e a posição $i$ é o produto escalar entre o documento $i$ e a consulta. `np.save`/`np.load` gravam e leem matrizes em arquivos `.npy`.

== Chamadas HTTP com `urllib.request`

A LLM roda no Ollama, que recebe pedidos pela rede local. O código não usa bibliotecas externas para isso, só a biblioteca padrão:

```python
request = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"),
                                 headers={"Content-Type": "application/json"})
with urllib.request.urlopen(request, timeout=1800) as response:
    result = json.loads(response.read().decode("utf-8"))
```

`json.dumps(...).encode("utf-8")` transforma o dicionário com o pedido em bytes; passar `data` faz o pedido ser um *POST*. `urlopen` envia, espera a resposta (até `timeout` segundos) e a devolve como bytes, que voltam a ser dicionário com `json.loads`. O `with` garante que a conexão é fechada. O mesmo `urlopen` é usado para baixar o dataset.

== Sorteios reprodutíveis com `random.Random`

`random.Random(42)` cria um gerador de números aleatórios próprio, com seed 42. Com a mesma seed, a sequência sorteada é sempre a mesma, em qualquer máquina, e o gerador não interfere em outros sorteios do programa. O projeto usa isso para sortear as consultas do RAG (`.sample`), os erros ortográficos (`.choice`) e a ordem das respostas na avaliação às cegas (`.shuffle`, que embaralha uma lista no lugar).
