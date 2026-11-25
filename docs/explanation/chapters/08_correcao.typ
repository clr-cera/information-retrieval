#import "../estilo.typ": *

= Correção ortográfica (`ir/lexical.py`, parte 3)

== Teoria

Na busca lexical, um termo digitado errado simplesmente não existe no índice e é descartado. Em consultas curtas, isso pode apagar a informação principal: "fenugbreek" no lugar de "fenugreek" deixa a consulta vazia. A correção ortográfica troca termos desconhecidos pela palavra mais parecida do vocabulário, em três etapas.

=== 1. Candidatos por k-gramas

Um *k-grama* é uma sequência de $k$ caracteres consecutivos. Para marcar o início e o fim da palavra, acrescentam-se `^` e `$`. Com $k = 2$ (bigramas):

- `food` → `^f`, `fo`, `oo`, `od`, `d$`
- `foodo` → `^f`, `fo`, `oo`, `od`, `do`, `o$`

Palavras parecidas compartilham muitos k-gramas. Um *índice de k-gramas* associa cada k-grama aos termos do vocabulário que o contêm. Os candidatos para corrigir um termo são todos os termos que compartilham pelo menos um k-grama com ele. Isso evita comparar o termo com todas as 36 mil palavras do dicionário.

=== 2. Filtro pelo coeficiente de Jaccard

O *coeficiente de Jaccard* mede a sobreposição entre os conjuntos de k-gramas $A$ e $B$:
$ J(A, B) = (|A inter B|) / (|A union B|) $

Para `food` e `foodo`: há 4 bigramas em comum (`^f`, `fo`, `oo`, `od`) e 7 no total, então $J = 4\/7 approx "0,571"$. Candidatos com $J$ abaixo de um limiar são descartados. O cálculo é barato e elimina a maior parte dos candidatos antes da etapa mais cara.

=== 3. Seleção pela distância de edição

A *distância de Levenshtein* é o menor número de inserções, remoções e substituições de caracteres que transforma uma palavra na outra. `food` → `foodo` tem distância 1 (uma inserção). A troca de ordem de dois caracteres (`practices` → `parctices`) custa 2, porque a Levenshtein não tem uma operação de troca.

O cálculo usa *programação dinâmica*: uma tabela em que a célula $D[i][j]$ é a distância entre os $i$ primeiros caracteres de uma palavra e os $j$ primeiros da outra.

$ D[i][j] = min cases(D[i-1][j] + 1 & "(remoção)", D[i][j-1] + 1 & "(inserção)", D[i-1][j-1] + [a_i != b_j] & "(substituição, custo 0 se os caracteres são iguais)") $

Exemplo, `casa` (linhas) → `cesta` (colunas):

#tabela(
  (auto, auto, auto, auto, auto, auto, auto),
  [], [""], [c], [e], [s], [t], [a],
  [""], [0], [1], [2], [3], [4], [5],
  [c], [1], [0], [1], [2], [3], [4],
  [a], [2], [1], [1], [2], [3], [3],
  [s], [3], [2], [2], [1], [2], [3],
  [a], [4], [3], [3], [2], [2], [*2*],
)

A distância é o valor da última célula: 2 (substituir `a` por `e` e inserir `t`).

O candidato escolhido é o de menor distância; os empates são resolvidos pelo maior Jaccard, depois pela maior frequência na coleção (a palavra mais comum é mais provável) e, por fim, pela ordem alfabética.

== O código: correção

Imports desta parte: `random` (sorteio dos erros), `string` (o alfabeto `string.ascii_lowercase`), `Counter`, `Iterable`, `Mapping` e `dataclass`.

#funcao("ERROR_TYPES = (\"insercao\", \"remocao\", \"substituicao\", \"transposicao\")")[Os quatro tipos de erro pedidos pelo enunciado.]

#funcao("class CorrectionCandidate(term, edit_distance, jaccard, frequency)")[Um candidato a correção, com os três critérios de ordenação.]

#funcao("def tokenize_for_correction(text: str) -> list[str]")[`normalize(tokenize(text))`: só tokenização e minúsculas, *sem* stopwords nem stemming.]

#funcao("def build_dictionary(documents) -> Counter[str]")[
  O dicionário da correção: aplica `tokenize_for_correction` a cada documento e conta as ocorrências. O enunciado exige que o dicionário tenha os termos *antes* do stemming: a correção precisa propor palavras reais, como `studies`, e não radicais, como `studi`. O resultado tem 36.477 termos.
]

#funcao("def k_grams(term: str, k: int) -> frozenset[str]")[
  Acrescenta `^` e `$` e pega todas as fatias de tamanho `k` (`padded[index : index + k]`). Se a palavra com marcadores tem até `k` caracteres, devolve ela inteira. Devolve um `frozenset` (conjunto imutável), porque a ordem e as repetições não importam para o Jaccard.
]

#funcao("def jaccard_similarity(first, second) -> float")[Interseção (`&`) sobre união (`|`) dos dois conjuntos; 0 se ambos forem vazios.]

#funcao("def levenshtein_distance(first: str, second: str) -> int")[
  Programação dinâmica guardando só *duas linhas* da tabela (`previous` e `current`), porque cada célula depende apenas da linha anterior e da célula à esquerda. Isso usa memória proporcional ao tamanho da palavra menor, e não ao produto dos tamanhos. Para isso, troca as palavras de lugar se preciso (`first` fica sendo a mais longa). A primeira linha é `0, 1, 2, ...` (transformar o vazio em prefixos da outra palavra); cada nova linha começa com o número da linha. `(first_char != second_char)` vale 1 ou 0. Devolve a última célula.
]

#funcao("class SpellingCorrector(vocabulary, kgram_size=3, jaccard_threshold=0.3, max_edit_distance=2, max_candidates=10)")[
  No construtor:
  - aceita um dicionário com frequências (o `Counter`) ou só uma lista de palavras (frequência 1 para todas);
  - valida os limiares;
  - calcula os k-gramas de cada termo (`term_grams`) e monta o índice de k-gramas (`kgram_index`: k-grama → conjunto de termos).

  O sistema usa `kgram_size=2`, `jaccard_threshold=0.2` e `max_edit_distance=2`, valores escolhidos no dev e lidos do config pelos scripts; os valores padrão do construtor não são usados.
]

#funcao("def candidates(self, token) -> list[CorrectionCandidate]")[
  Se o token existe no vocabulário, ele mesmo é o único candidato. Senão: junta os termos de todas as posting lists dos k-gramas do token; para cada candidato, calcula o Jaccard e descarta os abaixo do limiar; calcula a distância de edição e descarta os acima do máximo; ordena por `(distância, -jaccard, -frequência, termo)` e devolve os 10 primeiros.
]

#funcao("def correct_token(self, token) -> str / correct_tokens(tokens) / correct_query(query)")[
  `correct_token` devolve o próprio token se ele é conhecido; senão, o melhor candidato; e, se não houver candidatos, o próprio token. `correct_query` tokeniza a consulta, corrige cada token e junta com espaços. O resultado está em minúsculas e sem pontuação, mas isso não muda a busca, porque o BM25 aplica o mesmo pré-processamento.
]

== O código: geração de erros para o experimento

#funcao("def generate_error_variants(term, error_type) -> list[str]")[
  Gera *todas* as variantes de um tipo de erro:
  - inserção: cada letra do alfabeto em cada posição;
  - remoção: tira cada caractere (se a palavra tiver mais de um);
  - substituição: troca cada caractere por cada outra letra;
  - transposição: troca cada par de caracteres vizinhos diferentes.

  Remove repetições mantendo a ordem (com um conjunto `seen`).
]

#funcao("def inject_error(term, error_type, vocabulary, rng=None) -> str | None")[
  Gera as variantes e mantém só as que *não* estão no vocabulário. É a regra (ii) do enunciado: um erro que forma outra palavra válida (por exemplo, `food` → `good`) não seria detectado pelo corretor. Sorteia uma com o gerador `rng`, ou pega a primeira se não houver gerador. Devolve `None` se nenhuma variante servir.
]

#funcao("def inject_query_error(query, error_type, vocabulary, rng=None, excluded_tokens=(), min_token_length=4) -> InjectedError | None")[
  Escolhe o termo da consulta que vai receber o erro: entre os tokens com pelo menos 4 caracteres, só letras, presentes no vocabulário e fora de `excluded_tokens` (as stopwords), ordena do *mais longo* para o mais curto. Tenta gerar o erro no primeiro; se não conseguir, passa ao próximo. Devolve um `InjectedError` com a consulta modificada, o termo original, o termo com erro e o tipo.
]

#funcao("def _vocabulary_set(vocabulary) -> set[str]")[Converte o vocabulário para conjunto, se ainda não for, para buscas rápidas.]

== Como o experimento usa essas funções

O script `run_typo.py` (no @cap-scripts) junta tudo: escolhe as 10 primeiras consultas do test com NDCG\@10 maior que zero, gera um erro por consulta alternando os tipos, corrige com `SpellingCorrector` e mede o NDCG\@10 das três versões no BM25. O script `tune_typo.py` escolhe os limiares no dev, medindo a fração de 200 erros simulados corrigidos exatamente: a configuração escolhida acertou 92%. Com distância máxima 1, o acerto cai para cerca de 71%, porque as transposições (distância 2) não podem ser corrigidas.

No test, as 10 correções recuperaram a palavra original, e o NDCG\@10 médio voltou de 0,1625 (com erro) para 0,4706 (original).
