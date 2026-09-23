== Comparação entre Modelo Vetorial e Modelo Probabilístico

Para realizar a comparação entre os dois modelos, o modelo probabilístico recebeu parâmetros fixos $k=1.2$ e $b=1.0$. As métricas utilizadas para comparação foram Precision, Recall e MAP.

=== Curva Precision x Recall

Na curva do gráfico Precision x Recall, cada ponto representa um top-k, com P\@k e R\@k definidos como a média de todas as queries executadas.

#figure(image("../../plots/precision_vs_recall_all_groups_combined.png", width: 100%))

Analisando a figura, é fácil averiguar que, em todos os casos, *o modelo probabilístico foi superior ao vetorial* com uma boa margem entre o pior do modelo probabilístico e o melhor do modelo vetorial (cerca de 5%).

Para o modelo *probabilístico*, existem duas duplas de grupos semelhantes: `WithStopRemovalWithStemming` e `NoStopRemovalWithStemming` apresentaram desempenho semelhante e claramente superior a `WithStopRemovalNoStemming` e `NoStopRemovalNoStemming` (também semelhantes). Isso evidencia que o tratamento de strings que afeta mais positivamente o modelo é a aplicação do stemming. Ao final da curva, é possível ver que a remoção de stop words forneceu uma pequena vantagem de modo geral.

Para o modelo *vetorial*, também existem duas duplas de grupos semelhantes, mas comportamento inverso: `WithStopRemovalWithStemming` e `NoStopRemovalNoStemming` foram superiores a `WithStopRemovalNoStemming` e `NoStopRemovalWithStemming`. Isso evidencia que, no modelo vetorial, o tratamento mais significativo é a remoção de stop words. O stemming fornece apenas uma pequena vantagem de modo geral.

Dadas as observações, pode-se aferir a causa.

No modelo *probabilístico*, a variação pequena ao alternar a aplicação da remoção de stop words evidencia que o modelo lida muito bem com palavras que se repetem em quase todos os arquivos, conseguindo reduzir sua relevância ao nível esperado. Isto provavelmente se deve ao parâmetro de penalização por *tamanho do documento*. 

Já a grande variação na presença do stemming pode transparecer um defeito: O modelo é facilmente influenciável pela frequência dos termos, ganhando eficiência quando os termos são agrupados ("andar", "andou", "andei" -> "and"), o que retira a influência de termos únicos. Para testar essa hipótese, foi aplicado `log` aos termos de frequência da equação do BM25, de modo que:

$ "score"(d,q) = sum_(t in q) I D F(t)(log(1+t f(t, d))(k_1+1))/(log(1+t f(t, d))+k_1(1-b+(b(|d|)/"avgdl")) $

#figure(image("../../plots/precision_vs_recall_bim25_modified_all_groups_combined.png", width: 100%))

O desempenho do BM25 diminuiu. Mas note que a divisão em duplas por presença de stemming já praticamente não existe mais: os desempenhos se aproximaram, de modo que apenas stemming e apenas remoção de stop words apresentaram desempenho próximo a partir de k=5. Isso confirma a sensibilidade do BM25 a termos muito frequentes no documento, mas também mostra que essa sensibilidade é necessária para sua eficiência.

No modelo *vetorial*, a variação pequena ao alternar a aplicação de stemming pode evidenciar um ponto forte do modelo: Quanto a frequência das palavras no documento correlatas à query aumenta muito, o modelo lida bem com isso. Diferente de stop words, palavras com stemming se aproximam e identificam melhor documentos com temas específicos ("medicar", "medicando", "medicamento" -> "medic"). Isso não é tratado pelo *IDF*, mas sim pelo logaritmo que amortece a influência da frequência do termo no peso final.

Já a grande variação ao alternar a remoção de stop words transparece um defeito do modelo vetorial: Como stop words são muito comuns entre query e documento, o vetor de ambos começa a ficar poluído e com ruídos, piorando drasticamente a acurácia do modelo devido a dimensões extras desnecessárias. Isto provavelmente é uma falha da similaridade por cosseno, apesar do termo de controle *IDF*.

=== Comparação de MAP

Em ordem decrescente, as pontuações MAP para as variações do modelo probabilístico e vetorial se encontram no gráfico abaixo.

#figure(image("../../plots/probabilistic_vs_vectorial_map.png", width: 100%))

Novamente, o modelo probabilístico se mostra superior ao modelo vetorial.

No modelo probabilístico, o stemming se mostrou como mais relevante no incremento do MAP do que a remoção de stop words.

Já no modelo vetorial, a remoção de stop words se mostrou como mais relevante no incremento do MAP do que o stemming, mas com menor discrepância do que no modelo probabilístico.

O comportamento observado na curva de Precision x Recall se repete no MAP, fortalecendo as hipóteses apresentadas.


