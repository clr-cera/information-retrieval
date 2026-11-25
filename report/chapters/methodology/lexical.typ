== Busca lexical (BM25)

=== Escolha do modelo

O baseline lexical escolhido foi o *BM25*, reaproveitado do Trabalho Prático 1 (classe `ProbabilisticModel`, `ir/lexical.py`). O mesmo modelo, com os mesmos parâmetros, é usado em todos os experimentos seguintes: tolerância a erros, busca híbrida, reranking e RAG. A escolha se apoia em três evidências.

- *Resultados do TP1.* No Cranfield, o BM25 superou o Modelo Vetorial (TF-IDF com cosseno) na curva Precision × Recall e no MAP, em todos os quatro pipelines de pré-processamento. Lá, o Modelo Vetorial se mostrou mais sensível à presença de termos muito frequentes.
- *Comparação no conjunto dev do NFCorpus.* Com o mesmo pré-processamento e os parâmetros adotados ($k_1 = "1,2"$; $b = "0,75"$), o BM25 obteve NDCG\@10 de 0,2906, contra 0,2880 do TF-IDF com cosseno, além de P\@10 maior (0,2324 contra 0,2272) e AP\@10 praticamente igual (0,0898 contra 0,0891). O TF-IDF teve R\@10 um pouco maior (0,1303 contra 0,1281). Por consulta, o TF-IDF foi melhor em 86 das 324 consultas, o BM25 em 82, e houve empate em 156: o BM25 vence na média porque suas vitórias são, em média, por margens maiores. A vantagem do BM25 no NFCorpus é, portanto, pequena: ela confirma a direção observada no TP1, mas não é decisiva por si só.
- *Controle explícito de saturação e de tamanho.* O BM25 tem dois parâmetros com interpretação direta, que puderam ser ajustados no dev: $k_1$ (saturação da frequência do termo) e $b$ (normalização pelo tamanho do documento). Ele também é o baseline lexical usado pelo próprio benchmark BEIR, o que facilita comparar os resultados com a literatura.

Na comparação acima, o TF-IDF usou pesos $(1 + log t f) dot log(N \/ n_t)$ e cosseno com a norma do vetor *completo* do documento. A implementação do TP1 calculava a norma do documento usando apenas os termos da consulta, o que não corresponde ao cosseno usual; por isso, uma versão corrigida foi usada só nesta comparação.

=== Função de ranqueamento

Para uma consulta $q$ e um documento $d$, o score é:

$ "score"(d, q) = sum_(t in q) "IDF"(t) dot (t f(t, d) dot (k_1 + 1)) / (t f(t, d) + k_1 dot (1 - b + b dot (|d|) / "avgdl")) $

$ "IDF"(t) = log(1 + (N - n_t + "0,5") / (n_t + "0,5")) $

em que $t f(t, d)$ é a frequência do termo no documento, $n_t$ é o número de documentos que contêm o termo, $N$ é o número de documentos, $|d|$ é o tamanho do documento e $"avgdl"$ é o tamanho médio. O "$1 +$" dentro do logaritmo garante IDF positivo mesmo para termos presentes em mais da metade da coleção. Cada termo distinto da consulta contribui uma vez: a frequência do termo na própria consulta não é usada, o que é adequado a consultas curtas como as do NFCorpus. Todas essas estatísticas vêm do índice invertido, e o score é calculado percorrendo apenas as posting lists dos termos da consulta, como descrito na seção anterior.

=== Escolha dos parâmetros $k_1$ e $b$

Os parâmetros foram avaliados *exclusivamente no conjunto dev*, junto com o pré-processamento, sobre a grade $k_1 in {"0,5"; "1,2"; "2,0"}$ × $b in {0; "0,75"; "1,0"}$ (script `tune_lexical.py`). Os valores usuais da literatura são $k_1 = "1,2"$ e $b = "0,75"$. A @tab-bm25 mostra o resultado para o pipeline selecionado (com remoção de stopwords e com stemming).

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: 4,
      align: (left, right, right, right),
      table.header([*$k_1$*], [*$b = 0$*], [*$b = "0,75"$*], [*$b = "1,0"$*]),
      [0,5], [0,2878], [0,2864], [0,2854],
      [1,2], [0,2899], [*0,2906*], [0,2894],
      [2,0], [#underline[0,2916]], [0,2904], [0,2914],
    )
  },
  caption: [NDCG\@10 médio no conjunto dev (324 consultas) para cada combinação de $k_1$ e $b$, com remoção de stopwords e stemming. Em negrito, a configuração adotada (valores usuais); sublinhado, o maior valor da grade.],
) <tab-bm25>

O sistema final usa os *valores usuais*, $k_1 = "1,2"$ e $b = "0,75"$ (NDCG\@10 = 0,2906 no dev). O maior valor da grade foi $k_1 = "2,0"$ e $b = 0$ (0,2916), mas ele não foi adotado, por três motivos:

- *O efeito dos parâmetros é pequeno.* Toda a grade fica entre 0,2854 e 0,2916, e a diferença entre o maior valor e os valores usuais é de apenas 0,001.
- *A vantagem de $b = 0$ não é confiável.* Com $b = 0$, muitos documentos recebem exatamente o mesmo score, e só a ordem de desempate faz o NDCG\@10 do dev variar 0,017, muito mais do que essa diferença (ver a subseção seguinte). Com os valores usuais, quase não há empates, e as métricas praticamente não dependem do desempate.
- *Os valores usuais são o padrão da literatura* e não exigem justificativa específica para esta coleção.

A decisão continua baseada apenas no conjunto dev: o conjunto test não foi usado para comparar as configurações.

O pequeno efeito de $b$ no NFCorpus tem explicação nos dados da coleção. A normalização por tamanho existe para compensar a vantagem de documentos longos, que tendem a conter os termos da consulta mais vezes sem serem mais relevantes. No NFCorpus, essa situação é rara:

- *Os documentos têm tamanho homogêneo.* Após o pré-processamento, o tamanho médio é de 155,0 termos (mediana 157), com desvio padrão de 58,0 (coeficiente de variação de 0,37). 80% dos documentos têm entre 87 e 212 termos, e apenas 1% passa de 293 termos. Como quase todos os documentos são resumos de artigos, $|d| \/ "avgdl"$ fica próximo de 1 na maior parte da coleção, e o fator de normalização muda pouco o score.
- *A relevância não depende do tamanho.* No dev, os documentos julgados relevantes têm em média 156,2 termos, praticamente a média da coleção (155,0). Dividindo a coleção em quartis de tamanho, a fração de documentos relevantes para alguma consulta do dev é de 83,8%, 86,8%, 87,0% e 85,8%, do menor para o maior quartil.

Assim, ligar ou desligar a normalização por tamanho altera pouco a qualidade média do ranking. O principal efeito prático de $b > 0$ nesta coleção é diferenciar documentos que, de outra forma, teriam o mesmo score.

=== Empates de score

Quando dois documentos têm exatamente o mesmo score, o ranking mantém a ordem em que eles foram encontrados nas posting lists dos termos da consulta, que segue a ordem dos documentos no `corpus.jsonl`. Esse critério é determinístico (a mesma execução sempre produz o mesmo ranking), mas é arbitrário do ponto de vista da relevância. Um desempate explícito (por exemplo, por `doc_id`) foi considerado, mas não foi implementado, por ser opcional e por não ter justificativa de relevância melhor do que a ordem atual.

Com $b = 0$, os empates são frequentes: sem a normalização por tamanho, o score depende apenas do $t f$ e do IDF dos termos da consulta, e as consultas têm poucos termos. Assim, documentos com as mesmas frequências dos mesmos termos recebem exatamente o mesmo score. No dev, 93 das 324 consultas têm um empate entre a 10ª e a 11ª posição, e no test, 107 das 323. Com $b = "0,75"$, apenas 3 consultas do dev têm esse tipo de empate, porque o tamanho do documento quase sempre diferencia os scores.

A @tab-ties mostra o quanto as métricas do dev dependem da ordem dentro dos empates. As linhas "melhor" e "pior caso" são limites teóricos, obtidos colocando os documentos relevantes no início ou no fim de cada grupo empatado; elas não são estratégias aplicáveis, porque usam os qrels.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: 3,
      align: (left, right, right),
      table.header([*Ordem dentro dos empates*], [*NDCG\@10 ($k_1$ = 2,0; $b$ = 0)*], [*NDCG\@10 ($k_1$ = 1,2; $b$ = 0,75)*]),
      [Ordem atual (posting lists)], [0,2916], [0,2906],
      [Por `doc_id` crescente], [0,2932], [0,2908],
      [Por `doc_id` decrescente], [0,2929], [0,2906],
      [Melhor caso (limite teórico)], [0,3021], [0,2915],
      [Pior caso (limite teórico)], [0,2850], [0,2899],
    )
  },
  caption: [Sensibilidade do NDCG\@10 médio no conjunto dev à ordem de desempate do BM25.],
) <tab-ties>

Com $b = 0$, a ordem de desempate pode mover o NDCG\@10 do dev em até 0,017 (de 0,2850 a 0,3021). Isso é muito mais do que a diferença de 0,001 entre essa configuração e os valores usuais. Portanto, a vantagem de $b = 0$ no dev está dentro da variação causada pelos empates e não indica uma superioridade real. Com os valores usuais, adotados no sistema final, a mesma variação fica entre 0,2899 e 0,2915, e o ranking lexical praticamente não depende do critério de desempate.
