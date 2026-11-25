== Reranking

O reranking é o melhor sistema em NDCG\@10 (+0,0117 sobre o híbrido) e em MAP\@10 (+0,0123), métricas que valorizam a posição dos relevantes (@tab-all-systems). O P\@10 cai um pouco (0,2557 → 0,2505): os relevantes sobem, mas não entram mais relevantes no top-10. O efeito varia muito: o NDCG\@10 melhorou em 108 consultas, piorou em 97 e não mudou em 118, a um custo de cerca de 4,1 s por consulta em CPU.

=== Análise de casos

Os casos foram selecionados pela diferença de NDCG\@10 entre o reranking e o híbrido (`analyze_reranking.py`). Para os documentos que mais mudaram, indica-se a posição no híbrido → após o reranking e o score do cross-encoder, que não tem escala fixa (só a ordem importa).

*Maior ganho — PLAIN-2081, "shelf life"* (NDCG\@10 0 → 1). O único relevante, MED-4303 ("Oxidative stability and shelf-life evaluation of selected culinary oils"), sobe de 34 para *1* (score 0,85; o 2º tem −1,37). No BM25, "shelf-life" vira `shelflif`, que não casa com `shelf` e `life`, e o documento fica fora dos 100 primeiros. Sem essa contribuição, o híbrido o deixava em 34º, embora o semântico o tivesse em 15º. O 1º do híbrido, MED-2510 ("...life extension via dietary restriction"), contém "life", mas não "shelf", e cai para 10. O cross-encoder lê "shelf", "-" e "life" como pedaços separados e reconhece a expressão.

*Segundo maior ganho — PLAIN-681, "betel nuts"* (0 → 1). O relevante, MED-5017 ("Association between betel-nut chewing and chronic kidney disease in men"), sobe de 12 para *1* (4,31, contra −2,13 do 2º). O hífen gera o termo `betelnut`, e o documento não está entre os 100 primeiros do BM25. O híbrido o deixava abaixo de artigos sobre castanhas, que casam com "nuts". O cross-encoder distingue a noz de bétele (mastigada) das castanhas, que recebem scores negativos.

*Pouca alteração — PLAIN-1039, "domoic acid"* (1 → 1). Os dois relevantes já estavam em 1º e 2º e continuam lá, com os maiores scores (7,94 e 4,93). Um deles, MED-4381 ("Amnesic shellfish poison"), nem tem "domoic" no título, mas trata da intoxicação por essa toxina. Abaixo deles, o reranking só reordena documentos não relevantes sobre outros ácidos (salicílico, úrico, araquidônico), sem afetar o NDCG\@10.

*Maior piora — PLAIN-1679, "myelopathy"* (0,3869 → 0). O único relevante, MED-5142 ("Irreversible subacute sclerotic combined degeneration of the spinal cord in a vegan subject"), cai de 5 para *40* (−10,20). Ele descreve uma mielopatia sem usar a palavra, e o bi-encoder o colocava em 5º pelo sentido. O cross-encoder sobe documentos sobre *mieloma múltiplo*: MED-1105 vai de 32 para 1, e MED-1104, de 24 para 2. "Myelopathy" e "myeloma" compartilham os pedaços `my` e `##elo`, e o modelo dá peso a essa semelhança superficial, um caso de *ambiguidade*.

Ao ler consulta e documento juntos, o cross-encoder recupera relevantes perdidos pela tokenização (hífens) e distingue sentidos (bétele × castanhas). Mas, treinado no MS MARCO, ele valoriza a correspondência de palavras e pode preferir uma palavra parecida (myeloma) a um relevante escrito com outro vocabulário.
