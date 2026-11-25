== Reranking

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
      [Híbrido (RRF)], [*0,2557*], [0,1657], [0,1259], [0,3440],
      [*Híbrido + reranking*], [0,2505], [*0,1679*], [*0,1382*], [*0,3557*],
    )
  },
  caption: [Os quatro sistemas no conjunto test (323 consultas).],
) <tab-all-systems>

O reranking é o melhor sistema em NDCG\@10 (+0,0117 sobre o híbrido) e em MAP\@10 (+0,0123), métricas que valorizam a posição dos relevantes no topo. O P\@10 cai um pouco (de 0,2557 para 0,2505): o cross-encoder reorganiza os 50 candidatos, colocando os relevantes mais acima, mas não traz necessariamente mais relevantes para o top-10. O efeito varia muito entre consultas: o NDCG\@10 melhorou em 108 consultas, piorou em 97 e não mudou em 118. O custo é alto: cerca de 4,1 s por consulta em CPU, mais de 20 vezes o tempo da recuperação híbrida.

=== Análise de casos

Os casos foram selecionados pela diferença de NDCG\@10 entre o reranking e o híbrido (script `analyze_reranking.py`). Para cada um, mostram-se os documentos que mais mudaram de posição: grau de relevância, posição no híbrido → posição após o reranking, e score do cross-encoder (que não tem escala fixa; só a ordem importa).

*Maior ganho — PLAIN-2081, "shelf life"* (NDCG\@10 0 → 1). O único documento relevante, MED-4303 ("Oxidative stability and shelf-life evaluation of selected culinary oils"), sobe de 34 para *1* (score 0,85; o segundo colocado tem −1,37). No BM25, o título escreve "shelf-life", que a tokenização junta no termo `shelflif`, diferente dos termos da consulta (`shelf` e `life`): o documento fica fora dos 100 primeiros do lexical. O semântico o tinha na posição 15, e o híbrido, sem a contribuição lexical, na 34. Já o 1º do híbrido, MED-2510 ("...life extension via dietary restriction"), contém "life" (3 vezes), mas não "shelf"; estava em 17º no lexical e em 3º no semântico, e cai para 10. O cross-encoder lê o par inteiro, com "shelf", "-" e "life" como pedaços separados, e reconhece a expressão.

*Segundo maior ganho — PLAIN-681, "betel nuts"* (0 → 1). O relevante, MED-5017 ("Association between betel-nut chewing and chronic kidney disease in men"), sobe de 12 para *1* (score 4,31, contra −2,13 do segundo). Como em "shelf life", o hífen transforma "betel-nut" no termo `betelnut`, e o documento não está entre os 100 primeiros do BM25; o híbrido o deixava abaixo de vários artigos sobre consumo de castanhas e nozes, que casam com "nuts". O cross-encoder distingue a noz de bétele (mastigada) das castanhas comestíveis: os documentos sobre castanhas recebem scores negativos.

*Pouca ou nenhuma alteração — PLAIN-1039, "domoic acid"* (NDCG\@10 1 → 1). Os dois relevantes já estavam nas posições 1 e 2 do híbrido e continuam lá, com os scores mais altos (7,94 e 4,93). MED-4381 ("Amnesic shellfish poison") não tem "domoic" no título, mas trata da intoxicação causada por essa toxina, e o cross-encoder o mantém em 2º. Abaixo deles, o reranking reordena documentos sobre outros ácidos (salicílico, úrico, araquidônico), todos com scores negativos e não relevantes; essas mudanças não afetam o NDCG\@10.

*Maior piora — PLAIN-1679, "myelopathy"* (NDCG\@10 0,3869 → 0). O único relevante, MED-5142 ("Irreversible subacute sclerotic combined degeneration of the spinal cord in a vegan subject"), cai de 5 para *40* (score −10,20). O documento descreve uma mielopatia (lesão da medula espinhal) sem usar a palavra "myelopathy": o bi-encoder o colocava em 5º pelo significado. O cross-encoder, ao contrário, sobe documentos sobre *mieloma múltiplo* (MED-1105, de 32 para 1; MED-1104, de 24 para 2). "Myelopathy" e "myeloma" são divididos pelo tokenizador como `my`, `##elo`, `##pathy` e `my`, `##elo`, `##ma`: o modelo dá peso à semelhança superficial, um caso de *ambiguidade*, e penaliza um relevante que só é relevante por paráfrase. Os documentos MED-3193 e MED-3787 recebem o mesmo score (−2,5360) porque têm o mesmo texto (são duplicados na coleção).

Os quatro casos mostram o que o cross-encoder acrescenta e onde falha. Ele recupera relevantes que o BM25 perdeu por causa da tokenização (hífens) e diferencia sentidos ("betel nut" × castanhas), porque lê consulta e documento juntos. Mas, treinado no MS MARCO, ele valoriza a correspondência entre as palavras da consulta e do documento, e pode preferir uma palavra parecida (myeloma) a um documento relevante que usa outro vocabulário.
