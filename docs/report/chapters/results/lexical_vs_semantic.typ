== Busca lexical × busca semântica

=== Resultados globais

Os dois sistemas foram avaliados sobre as mesmas 323 consultas do conjunto test.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      table.header([*Sistema*], [*P\@10*], [*R\@10*], [*MAP\@10*], [*NDCG\@10*]),
      [Lexical (BM25)], [0,2307], [0,1411], [*0,1109*], [0,3124],
      [Semântico (bi-encoder)], [*0,2433*], [*0,1550*], [0,1108], [*0,3167*],
    )
  },
  caption: [Médias no conjunto test (323 consultas). Em negrito, o melhor valor de cada métrica.],
) <tab-lex-sem>

Nas médias, os dois sistemas são muito próximos. O semântico tem P\@10, R\@10 e NDCG\@10 um pouco maiores, e o MAP\@10 é praticamente igual (0,1109 contra 0,1108). Os valores de R\@10 são baixos para ambos porque as consultas têm, em média, 38 documentos relevantes, e um top-10 só pode mostrar parte deles.

As médias escondem diferenças grandes por consulta. Comparando o NDCG\@10 consulta a consulta, o semântico é melhor em 109 consultas, o lexical em 106, e os dois empatam em 108. Desses empates, 77 são consultas em que *nenhum* dos dois sistemas coloca um documento relevante no top-10. No total, o NDCG\@10 é zero em 102 consultas no lexical e em 100 no semântico, cerca de 31% das consultas em cada sistema. Como cada sistema acerta consultas diferentes, combinar os dois rankings tende a melhorar o resultado, o que motiva a busca híbrida.

=== Análise por consulta

Para cada consulta, calculou-se a diferença $Delta = "NDCG@10"_"semântico" - "NDCG@10"_"lexical"$ e foram selecionadas as 3 consultas de maior $Delta$ (vantagem do semântico) e as 3 de menor $Delta$ (vantagem do lexical), com empates resolvidos pelo identificador. A evidência foi gerada pelo script `analyze_lexical_vs_semantic.py`. Nas tabelas, cada célula traz o documento, o grau de relevância entre parênteses (relevantes em negrito) e o score (BM25 ou cosseno); "—" indica que não há documento naquela posição.

#let top5(..linhas) = {
  set par(justify: false)
  set text(size: 8pt)
  table(
    columns: (auto, 1fr, 1fr),
    inset: (x: 4pt, y: 3pt),
    align: (center, left, left),
    table.header([*Pos.*], [*Lexical (BM25)*], [*Semântico (cosseno)*]),
    ..linhas.pos().flatten(),
  )
}

#text(weight: "bold", fill: rgb("#4c566a"))[Consultas com vantagem do semântico]

*PLAIN-307 — "Vitamin D: Shedding some light on the new recommendations"* ($Delta = +"0,82"$; lexical 0,0000, semântico 0,8194; 3 relevantes).

#top5(
  ([1], [MED-3099 (0) 15,76], [*MED-714 (2)* 0,742]),
  ([2], [MED-4872 (0) 12,89], [MED-3988 (0) 0,696]),
  ([3], [MED-3373 (0) 12,41], [MED-3987 (0) 0,677]),
  ([4], [MED-1579 (0) 10,56], [*MED-919 (2)* 0,664]),
  ([5], [MED-1777 (0) 10,32], [MED-3990 (0) 0,648]),
)

O pré-processamento lexical perde a parte mais importante da consulta: o "D" de "Vitamin D" é removido como stopword, e sobram `vitamin`, `shed`, `light`, `new` e `recommend`. O termo `shed` aparece em apenas 13 documentos e tem IDF alto, de modo que o BM25 favorece documentos que usam a expressão figurada "shed light" em outros contextos: MED-3099 ("sheds new light", sobre receptores de hidrocarbonetos) e MED-1579 ("shed light on potential options", sobre doença de Crohn) não tratam de vitamina D. É um caso de *ambiguidade*: a correspondência lexical acontece em palavras que não carregam o tema da consulta. O bi-encoder representa o significado da frase inteira e coloca em 1º e 4º os dois documentos de grau 2 (prevenção da deficiência de vitamina D e a diretriz da Endocrine Society), que o BM25 deixa nas posições 25 e 12.

*PLAIN-1537 — "low-carb diets"* ($Delta = +"0,66"$; lexical 0,0000, semântico 0,6618; 45 relevantes).

#top5(
  ([1], [MED-4880 (0) 17,07], [*MED-4515 (1)* 0,662]),
  ([2], [MED-4848 (0) 2,58], [MED-4880 (0) 0,609]),
  ([3], [MED-5267 (0) 2,57], [*MED-4514 (1)* 0,596]),
  ([4], [MED-1374 (0) 2,55], [*MED-1616 (1)* 0,587]),
  ([5], [MED-3786 (0) 2,55], [*MED-2586 (1)* 0,558]),
)

Um caso de *variação de vocabulário* agravado pela tokenização. A consulta vira os termos `lowcarb` e `diet`. Os documentos relevantes escrevem "low-carbohydrate" (27 ocorrências nos relevantes), que o índice transforma em outro termo, `lowcarbohydr`. O termo `lowcarb` existe em um único documento (MED-4880, não relevante), que recebe score 17,07; todos os demais dependem só de `diet`, presente em 1.029 documentos e com IDF baixo, e o BM25 traz dietas mediterrâneas e vegetarianas com scores próximos de 2,6. Só 25 dos 45 relevantes contêm algum termo da consulta. O bi-encoder reconhece que "low-carb" é a abreviação de "low-carbohydrate": 4 dos 5 primeiros documentos são relevantes, e 3 deles não aparecem entre os 100 primeiros do BM25.

*PLAIN-418 — "Fresh fruit versus frozen--which is better?"* ($Delta = +"0,66"$; lexical 0,2057, semântico 0,8671; 3 relevantes).

#top5(
  ([1], [MED-3469 (0) 11,81], [*MED-917 (2)* 0,582]),
  ([2], [MED-3203 (0) 11,35], [*MED-3714 (2)* 0,530]),
  ([3], [MED-2453 (0) 11,29], [MED-3738 (0) 0,490]),
  ([4], [MED-5327 (0) 10,83], [MED-3946 (0) 0,490]),
  ([5], [*MED-917 (2)* 10,44], [MED-2285 (0) 0,475]),
)

O termo que define a consulta desaparece na busca lexical: a tokenização junta "frozen--which" em `frozenwhich`, que não existe em nenhum documento. O BM25 fica só com termos genéricos (`fresh`, `fruit`, `versu`, `better`) e prioriza documentos sobre suco de laranja ou toranja. Mesmo que "frozen" sobrevivesse, o stemming não o aproximaria de "freezing" (`frozen` × `freez`), a forma usada no título do documento relevante MED-917 ("Effect of freezing and storage..."). O bi-encoder captura a relação entre *paráfrases e formas diferentes da mesma palavra* (frozen, freezing, freeze-dried) e coloca os dois documentos de grau 2 no topo; o segundo deles (MED-3714, sobre morangos "fresh, frozen and freeze-dried") está na posição 39 do BM25.

#text(weight: "bold", fill: rgb("#4c566a"))[Consultas com vantagem do lexical]

*PLAIN-1473 — "kohlrabi"* ($Delta = -"1,00"$; lexical 1,0000, semântico 0,0000; 1 relevante).

#top5(
  ([1], [*MED-4455 (1)* 11,60], [MED-3947 (0) 0,220]),
  ([2], [—], [MED-4660 (0) 0,217]),
  ([3], [—], [MED-3441 (0) 0,216]),
  ([4], [—], [MED-3447 (0) 0,213]),
  ([5], [—], [MED-5024 (0) 0,213]),
)

Um *termo técnico raro*: `kohlrabi` (couve-rábano) aparece em um único documento da coleção, justamente o relevante, e o BM25 o coloca em 1º lugar com NDCG\@10 máximo. Para o bi-encoder, a palavra é desconhecida e é dividida em pedaços sem significado (`ko`, `##hl`, `##ra`, `##bi`). A maior similaridade é baixa (0,22, contra 0,30 a 0,74 do primeiro colocado nas outras cinco consultas analisadas) e apontam para extratos de hibisco, algas e microalgas. O documento relevante trata de sementes de cultivares de brócolis e cita "kohlrabi" apenas duas vezes; a primeira ocorrência está dentro dos 256 tokens lidos pelo modelo, então a falha não se deve ao truncamento. A explicação mais provável é que o embedding do documento, uma média sobre todos os tokens, representa o seu tema principal (brócolis), e não uma palavra citada de passagem. O documento não está entre os 100 primeiros do semântico.

*PLAIN-1288 — "grapes"* ($Delta = -"0,76"$; lexical 0,8900, semântico 0,1299; 196 relevantes).

#top5(
  ([1], [*MED-2668 (1)* 9,35], [MED-3200 (0) 0,426]),
  ([2], [*MED-2669 (1)* 9,16], [MED-3207 (0) 0,425]),
  ([3], [MED-2083 (0) 8,92], [MED-398 (0) 0,425]),
  ([4], [*MED-1538 (1)* 8,90], [MED-3210 (0) 0,424]),
  ([5], [*MED-5065 (1)* 8,76], [MED-2083 (0) 0,414]),
)

Um caso de *ambiguidade* criado pela tokenização em subpalavras. Os quatro primeiros documentos do semântico são sobre toranja (*grapefruit*), nenhum deles relevante. O tokenizador divide "grapefruit" em `grape`, `##fr`, `##uit`, de modo que a palavra compartilha o pedaço `grape` com a consulta. No índice lexical, o stemming mantém `grape` e `grapefruit` como termos diferentes, e o BM25 traz documentos sobre uva e suco de uva (4 relevantes no top-5). Observa-se ainda que MED-3207 e MED-398 têm exatamente o mesmo texto (documentos duplicados na coleção) e ocupam duas posições do top-5 semântico.

*PLAIN-792 — "cadaverine"* ($Delta = -"0,54"$; lexical 0,6448, semântico 0,1009; 6 relevantes).

#top5(
  ([1], [*MED-4958 (1)* 11,89], [MED-729 (0) 0,303]),
  ([2], [*MED-4546 (1)* 11,84], [MED-3601 (0) 0,287]),
  ([3], [*MED-4547 (1)* 7,50], [MED-732 (0) 0,282]),
  ([4], [—], [MED-1037 (0) 0,264]),
  ([5], [—], [MED-1041 (0) 0,257]),
)

Outro *termo técnico* em que a correspondência exata vence. Cadaverina é uma amina biogênica, e o radical `cadaverin` está em apenas 3 documentos da coleção, todos relevantes; o BM25 recupera exatamente esses 3. O tokenizador divide "cadaverine" em `cad`, `##aver`, `##ine`, os mesmos pedaços de "cadaver" (cadáver). O bi-encoder associa a consulta ao sentido de "cadáver" e traz documentos sobre carcaças bovinas e medicina no Egito antigo, nenhum relevante. Os documentos relevantes MED-4958 e MED-4546 aparecem só nas posições 7 e 14 do semântico.

#text(weight: "bold", fill: rgb("#4c566a"))[Síntese]

Os seis casos mostram padrões complementares. O semântico vence quando a correspondência exata de termos falha: *variação de vocabulário* e abreviações ("low-carb" × "low-carbohydrate"), *formas diferentes da mesma palavra* que o stemming não une (frozen × freezing) e perda de termos no pré-processamento (o "D" de vitamina D e a junção "frozen--which"). O lexical vence com *termos técnicos raros* (kohlrabi, cadaverine), que têm IDF alto e aparecem em poucos documentos, todos relevantes; para o bi-encoder, essas palavras são desconhecidas e viram pedaços que podem coincidir com palavras de outro sentido (grape × grapefruit, cadaverine × cadaver). Nos dois sentidos, a *ambiguidade* prejudica: a expressão "shed light" atrapalha o BM25, e as subpalavras atrapalham o bi-encoder.
