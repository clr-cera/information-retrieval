== Variação de parâmetros do BM25

Foram estudadas variações dos parâmetros $k_1$ e $b$ do modelo probabilístico. As variações são concernentes a $k_1 in {0.5, 1.2, 2.0}$ e $b in {0, 0.75, 1}$

=== MAP agrupado por parâmetros

Primeiro, é útil verificar como cada parâmetro se saiu nos pipelines.

#grid(
	columns: (1fr, 1fr), // 2 equal-width columns
	gutter: 10pt, // Space between

	figure(image("../../plots/metrics_probabilistic_k0.5_b0.0_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k0.5_b0.75_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k0.5_b1.0_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k1.2_b0.0_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k1.2_b0.75_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k1.2_b1.0_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k2.0_b0.0_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k2.0_b0.75_map.png", width: 100%)),
	figure(image("../../plots/metrics_probabilistic_k2.0_b1.0_map.png", width: 100%)),
)

De modo geral, são feitas as seguintes observações (aplicáveis somente ao universo de $k$ e $b$ testados):

+ A remoção de stop words junto com o stemming se estabelece em definitivo como o melhor tipo de processamento para todas as variações do BM25.
+ A ausência da remoção de stop words e de stemming se estabelece em definitivo como o pior tipo de processamento para todas as variações do BM25.
+ Somente stemming foi o segundo melhor processamento em definitivo, exceto quando $b=0.0$. Nesse caso, a remoção de stop words se define como o segundo melhor processamento.
+ Para todo $k$, todos os scores são significativamente melhores para $b = 0.75$ em comparação a $b = 0.0$
+ Para todo $k$, todos os scores são desprezivelmente melhores e, por vezes, desprezivelmente piores para $b=1.0$ em comparação a $b = 0.75$, mas com $b=0.75$ sempre melhor que $b=0.0$ para o mesmo $k$.
+ Para todo $b$, todos os scores são melhores para $k=1.2$ em comparação a $k=0.5$
+ Para $b=0.75$ e $b=1.0$, todos os scores são levemente melhores para $k=2.0$ em comparação a $k=1.2$. Para $b=0.0$, isso varia entre leve melhora/piora.

As observações 1 e 2 já eram esperadas. A observação 3 mostra que a ausência do parâmetro $b$ (penalidade por tamanho do doucumento) representa um problema quando não há remoção de stop words, de modo que somente a remoção de stop words se destaca frente ao stemming. Pela observação 4, também pode-se afirmar que a presença do parâmetro $b$ sempre resulta em melhora significativa na precisão. Por último, a observação 5 revela uma saturação do parâmetro $b$, de modo que penalizar demais pelo tamanho do documento resulta em perda de precisão.

As observações 6 e 7 revelam, igualmente, uma saturação do parâmetro $k$.

=== Mapa de bolhas P\@10 x R\@10

Ao verificar o comportamento para Precision x Recall ao longo de k=1 até k=10, a ordem do score das variações se manteve estável, de modo que pode-se analisar somente k=10 e inferir o mesmo para k < 10.

#figure(image("../../plots/precision_vs_recall_probabilistic_var_all_groups_bubble.png", width: 100%))

Em todos os casos, percebe-se, referente ao pipeline, uma ordem de eficiência: `WithStopRemovalWithStemming > NoStopRemovalWithStemming > WithStopRemovalNoStemming > NoStopRemovalNoStemming`. Essa observação foi feita em todas as análises anteriores.

No geral, percebe-se que as variações 5,6,8,9 sempre estão à frente das outras em todos os casos, alternando entre si. Assim, é válido considerá-los as melhores opções possíveis.

O melhor caso possível é `WithStopRemovalWithStemming` com $k=1.0$ e $b=0.75$.
