== Busca lexical × busca semântica

=== Resultados globais

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      table.header([*Sistema*], [*P\@10*], [*R\@10*], [*MAP\@10*], [*NDCG\@10*]),
      [Lexical (BM25)], [0,2307], [0,1411], [0,1109], [0,3124],
      [Semântico (bi-encoder)], [0,2433], [0,1550], [0,1108], [0,3167],
      [Híbrido (RRF, $k = 10$)], [*0,2557*], [0,1657], [0,1259], [0,3440],
      [Híbrido + reranking], [0,2505], [*0,1679*], [*0,1382*], [*0,3557*],
    )
  },
  caption: [Os quatro sistemas no conjunto test.],
) <tab-all-systems>

Nas médias, o lexical e o semântico são muito próximos: o semântico tem P\@10, R\@10 e NDCG\@10 um pouco maiores, e o MAP\@10 é praticamente igual. O R\@10 é baixo nos dois, indicando que eles têm menor capacidade de rankear documentos relevantes. O semântico vence em 109 consultas, o lexical em 106, e há 108 empates, 77 deles com NDCG\@10 zero nos dois sistemas. Como cada sistema acerta consultas diferentes, combinar os rankings tende a ajudar, o que faz a busca híbrida ser a melhor opção.

=== Análise por consulta

Foram selecionadas as 3 consultas de maior e as 3 de menor variação $Delta =  "NDCG@10"_"semântico" - "NDCG@10"_"lexical"$ (script `analyze_lexical_vs_semantic.py`). Em cada tabela, uma linha traz o documento, o grau de relevância entre parênteses (se for relevante, está em negrito) e o score (BM25 ou cosseno); "--" indica posição vazia.

A correção ortográfica não é aplicada nesta comparação.

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

O "D" de "Vitamin D" é removido como stopword, e sobram `vitamin`, `shed`, `light`, `new` e `recommend`. O termo `shed` está em só 13 documentos e tem IDF alto. Por isso, o BM25 favorece documentos que usam a expressão "shed light" em outros temas, como MED-3099 (receptores de hidrocarbonetos) e MED-1579 (doença de Crohn). Isso é um caso de ambiguidade semântica. O bi-encoder consegue captar o sentido da frase inteira e coloca em 1º e 4º os dois documentos de grau 2, que o BM25 deixa em 25º e 12º.

*PLAIN-1537 — "low-carb diets"* ($Delta = +"0,66"$; lexical 0,0000, semântico 0,6618; 45 relevantes).

#top5(
  ([1], [MED-4880 (0) 17,07], [*MED-4515 (1)* 0,662]),
  ([2], [MED-4848 (0) 2,58], [MED-4880 (0) 0,609]),
  ([3], [MED-5267 (0) 2,57], [*MED-4514 (1)* 0,596]),
  ([4], [MED-1374 (0) 2,55], [*MED-1616 (1)* 0,587]),
  ([5], [MED-3786 (0) 2,55], [*MED-2586 (1)* 0,558]),
)

A consulta vira `lowcarb` e `diet`, mas os relevantes escrevem "low-carbohydrate", que vira outro termo (`lowcarbohydr`). O termo `lowcarb` só existe no MED-4880, não relevante, que recebe score 17,07. Os demais documentos dependem só de `diet`, presente em 1.029 documentos e com IDF baixo, e só 25 dos 45 relevantes contêm algum termo da consulta. O bi-encoder associa "low-carb" a "low-carbohydrate": 4 dos 5 primeiros são relevantes, e 3 deles estão fora dos 100 primeiros do BM25.

*PLAIN-418 — "Fresh fruit versus frozen--which is better?"* ($Delta = +"0,66"$; lexical 0,2057, semântico 0,8671; 3 relevantes).

#top5(
  ([1], [MED-3469 (0) 11,81], [*MED-917 (2)* 0,582]),
  ([2], [MED-3203 (0) 11,35], [*MED-3714 (2)* 0,530]),
  ([3], [MED-2453 (0) 11,29], [MED-3738 (0) 0,490]),
  ([4], [MED-5327 (0) 10,83], [MED-3946 (0) 0,490]),
  ([5], [*MED-917 (2)* 10,44], [MED-2285 (0) 0,475]),
)

A tokenização junta "frozen--which" em `frozenwhich`, que não existe na coleção. O BM25 fica só com termos genéricos (`fresh`, `fruit`, `versu`, `better`) e traz documentos sobre sucos de frutas. Mesmo sem isso, o stemming não uniria `frozen` e `freez` ("freezing", no título do relevante MED-917). O bi-encoder relaciona *formas diferentes da mesma palavra* (frozen, freezing, freeze-dried) e põe os dois documentos de grau 2 no topo; o segundo deles (MED-3714) está em 39º no BM25.

#text(weight: "bold", fill: rgb("#4c566a"))[Consultas com vantagem do lexical]

*PLAIN-1473 — "kohlrabi"* ($Delta = -"1,00"$; lexical 1,0000, semântico 0,0000; 1 relevante).

#top5(
  ([1], [*MED-4455 (1)* 11,60], [MED-3947 (0) 0,220]),
  ([2], [—], [MED-4660 (0) 0,217]),
  ([3], [—], [MED-3441 (0) 0,216]),
  ([4], [—], [MED-3447 (0) 0,213]),
  ([5], [—], [MED-5024 (0) 0,213]),
)

`kohlrabi` é um termo muito raro, e aparece em um único documento, justamente o relevante, que o BM25 põe em 1º. O bi-encoder é incapaz de dar significado à palavra, por ser muito rara. A sua maior similaridade é baixa (0,22, contra 0,30 a 0,74 nas outras cinco consultas) e aponta para extratos de hibisco e algas. O relevante trata de brócolis e cita "kohlrabi" só duas vezes.

*PLAIN-1288 — "grapes"* ($Delta = -"0,76"$; lexical 0,8900, semântico 0,1299; 196 relevantes).

#top5(
  ([1], [*MED-2668 (1)* 9,35], [MED-3200 (0) 0,426]),
  ([2], [*MED-2669 (1)* 9,16], [MED-3207 (0) 0,425]),
  ([3], [MED-2083 (0) 8,92], [MED-398 (0) 0,425]),
  ([4], [*MED-1538 (1)* 8,90], [MED-3210 (0) 0,424]),
  ([5], [*MED-5065 (1)* 8,76], [MED-2083 (0) 0,414]),
)

Houve uma confusão entre palavras parecidas aqui. Os quatro primeiros documentos do semântico tratam de toranja (_grapefruit_), e nenhum é relevante. Para o bi-encoder, "grapes" e "grapefruit" ficam próximos porque começam da mesma forma, embora sejam frutas diferentes. As similaridades do top-5 também quase não variam (de 0,426 a 0,414): com uma consulta de uma só palavra, o modelo tem pouco contexto para separar os documentos. No índice lexical, `grape` e `grapefruit` são termos distintos, então o BM25 só pontua documentos que contêm `grape` e traz documentos sobre uva e suco de uva (4 relevantes no top-5).

*PLAIN-792 — "cadaverine"* ($Delta = -"0,54"$; lexical 0,6448, semântico 0,1009; 6 relevantes).

#top5(
  ([1], [*MED-4958 (1)* 11,89], [MED-729 (0) 0,303]),
  ([2], [*MED-4546 (1)* 11,84], [MED-3601 (0) 0,287]),
  ([3], [*MED-4547 (1)* 7,50], [MED-732 (0) 0,282]),
  ([4], [—], [MED-1037 (0) 0,264]),
  ([5], [—], [MED-1041 (0) 0,257]),
)

O radical `cadaverin` está em só 3 documentos, todos relevantes, e o BM25 recupera exatamente esses três. O bi-encoder traz documentos sobre carcaças bovinas e medicina no Egito antigo, e os relevantes MED-4958 e MED-4546 ficam em 7º e 14º. Novamente, o BM25 ganha em termos específicos.

*Conclusão:* O semântico vence quando a correspondência exata falha: variação de vocabulário e abreviações (low-carb × low-carbohydrate), formas da mesma palavra que o stemming não une (frozen × freezing) e termos perdidos no pré-processamento ("D", "frozen--which"). O lexical vence com termos técnicos raros (kohlrabi, cadaverine), de IDF alto, que o bi-encoder divide em pedaços que coincidem com outras palavras (grape × grapefruit, cadaverine × cadaver).
