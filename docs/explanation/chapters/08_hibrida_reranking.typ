#import "../estilo.typ": *

= Busca híbrida e reranking (`ir/neural.py`) <cap-hibrida>

== Reciprocal Rank Fusion

O BM25 acerta quando a consulta tem termos exatos (`ergothioneine`); a busca semântica, quando há sinônimos ou paráfrases. Combinar os dois rankings aproveita o melhor de cada um. Só que os scores não são comparáveis (o BM25 não tem limite; o cosseno fica entre −1 e 1). O *RRF* usa apenas as *posições*:

$ "RRF"(d) = sum_(s in {"lexical", "semântico"}) 1 / (k + "rank"_s (d)) $

A posição começa em 1, e um documento ausente de um ranking não recebe a parcela desse sistema. Com $k$ pequeno, o topo de cada sistema pesa muito mais do que o resto; com $k$ grande, as posições ficam parecidas.

*Exemplo* ($k = 10$) — lexical: d1, d2, d3; semântico: d2, d4, d1.

#tabela(
  (auto, auto, auto, auto),
  [*Documento*], [*Posições*], [*RRF*], [*Final*],
  [d2], [2 e 1], [$1\/12 + 1\/11 = "0,1742"$], [1º],
  [d1], [1 e 3], [$1\/11 + 1\/13 = "0,1678"$], [2º],
  [d4], [só semântico, 2], [$1\/12 = "0,0833"$], [3º],
  [d3], [só lexical, 3], [$1\/13 = "0,0769"$], [4º],
)

`reciprocal_rank_fusion` aplica a fórmula aos 100 primeiros de cada sistema (o ranking híbrido pode ter até 200 documentos) e desempata pelo identificador. No dev, $k = 10$ deu NDCG\@10 de 0,3299, contra 0,3273 de $k = 60$ e $k = 100$; o enunciado manda escolher o maior. No test, o híbrido chegou a *0,3440*, acima dos dois sistemas isolados.

== Reranking com cross-encoder

Um *cross-encoder* recebe o par `[CLS] consulta [SEP] documento [SEP]` como um único texto. A atenção relaciona cada palavra da consulta com cada palavra do documento, e o modelo devolve um score para o par.

#tabela(
  (auto, 1fr, 1fr),
  [], [*Bi-encoder*], [*Cross-encoder*],
  [Entrada], [consulta ou documento, sozinhos], [consulta e documento juntos],
  [Saída], [um vetor por texto], [um score por par],
  [Pré-cálculo], [sim (vetores dos documentos)], [não: uma passada pelo modelo por par],
  [Precisão × custo], [menor precisão, barato], [maior precisão, caro],
)

Por ser caro, o cross-encoder só *reordena os 50 primeiros* do híbrido; os documentos abaixo continuam depois, na mesma ordem, para que o ranking fique completo para as métricas. O modelo `cross-encoder/ms-marco-MiniLM-L6-v2` foi treinado no MS MARCO (consultas do Bing com trechos relevantes); seu score não tem escala fixa, só a ordem importa. Ele lê até 512 tokens por par: 8,8% dos pares do test são truncados.

No código, `CrossEncoderReranker` carrega o modelo e reordena uma consulta; `evaluate_reranker` aplica a todas e calcula as métricas. A lógica de reordenação (separar topo e resto, trocar os scores, reordenar o topo) fica em funções que recebem a função de score como parâmetro, o que permite testá-la com uma função falsa, sem carregar o modelo.

#atencao(titulo: "Scores misturados no CSV")[
  No `results_reranking.csv`, a coluna `score` tem o score do cross-encoder nas posições 1 a 50 e o score RRF nas posições 51 a 100. São escalas diferentes.
]

No dev, o `ms-marco-MiniLM-L6-v2` teve NDCG\@10 de 0,3310 (3,7 s por consulta) e o `ms-marco-TinyBERT-L2-v2`, 0,3237 (0,36 s); foi escolhido o primeiro. No test, o reranking chegou a *0,3557*, o melhor dos quatro sistemas, ao custo de cerca de 4 s por consulta em CPU.

=== O que os casos mostram

Por consulta, no test, o reranking melhorou 108, piorou 97 e não mudou 118. Os casos analisados (`analyze_reranking.py`):

- *"shelf life"* e *"betel nuts"* (NDCG\@10 de 0 para 1): os relevantes escrevem "shelf-life" e "betel-nut", que o BM25 transforma em `shelflif` e `betelnut`. O tokenizador do cross-encoder separa as partes, lê tudo junto com a consulta e põe o relevante em 1º. Em "betel nuts", ele ainda separa a noz de bétele das castanhas comestíveis.
- *"domoic acid"* (1 para 1): os relevantes já estavam em 1º e 2º e continuam lá.
- *"myelopathy"* (0,39 para 0): o relevante descreve a doença sem usar a palavra. O bi-encoder o tinha em 5º; o cross-encoder o derruba para 40º e sobe documentos sobre *mieloma*, que compartilha os pedaços `my ##elo`.

Resumo: o cross-encoder recupera relevantes perdidos pela tokenização e separa sentidos, mas, treinado no MS MARCO, valoriza a correspondência de palavras e pode preferir uma palavra parecida a uma paráfrase relevante.

== Montagem do pipeline a partir do config

A última parte de `ir/neural.py` liga o config aos sistemas: funções que leem cada escolha do bloco `selected` (com erro dizendo qual script de ajuste rodar, se ainda for `None`) e que constroem o run lexical, o run semântico e o ranking híbrido com essas escolhas. Assim, qualquer script monta o pipeline inteiro em poucas linhas, sempre com o que está registrado no config.
