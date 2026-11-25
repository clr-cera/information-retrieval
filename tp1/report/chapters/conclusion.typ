Pela análise da curva Precision x Recall, pode-se concluir que o modelo probabilístico BM25 é superior ao modelo vetorial. Além disso, eles são afetados pelo pipleine escolhido:

- No modelo *probabilístico*, o tratamento mais relevante é o stemming. A remoção de stop words possui baixa relevância, sendo mais decisivo nos primeiros resultados e se tornando quase inperceptível nos resultados posteriores. Verificou-se que a sensibilidade da presença do stemming é atenuada pela aplicação da operação de log na frequência do termo no denominador e numerador, mas diminui a eficácia.

- No modelo *vetorial*, o tratamento mais relevante é a remoção de stop words. O stemming possui baixa relevância, mas ainda assim é um fator discrepante ao longo de toda a curva. A presença de muitas palavras repetidas e frequentes se mostrou um ponto negativo para o cálculo de score por similaridade de cosseno.

O MAP da comparação entre probabilístico e vetorial confirma a superioridade do modelo probabilístico, além de confirmar os pipelines realmente relevantes para cada modelo, confirmando o que foi observado na curva Precision x Recall.

Na análise por consulta, pode-se verificar um padrão:

- O BM25 é superior quando a query contém *termos técnicos precisos* ou *palavras-chave exatas e discriminantes* ("rarefaction", "slip", "pressurized membrane cilinders").
- O modelo vetorial é superior quando a query exige *associação de conceitos/tokens*: "creep buckling", "ablative mass loss".
- Os dois modelos tiveram um desempenho quase nulo quando a query era uma *pergunta natural*: "what size of end plate...", "did anyone else discover...". Isso mostra que perguntas naturais são ruidosas por causa da *presença de termos muito comuns e pronomes*, como "what","can","be", etc.

Ao variar parâmetros no BM25, concluiu-se que tanto $k_1$ quanto $b$ saturam e possuem máximo desempenho em um ponto intermediário, denotado como $k=1.2$, $b=0.75$. Para todos os casos, o pipeline completo `WithStopRemovalWithStemming` se mostra mais uma vez como o mais eficiente, e o contrário (sem tratamento), como o mais ineficiente.

A ausência do parâmetro $b$ (penalidade do tamanho por documento) se mostrou muito negativa quando não há remoção de stop words, de modo que somente a remoção de stop words gera resultados melhores que só stemming nessa ocasião. Assim, o parâmetro $b$ se mostrou capaz de estabilizar a acurácia do modelo em função de documentos muito longos ou com muitas palavras repetidas.

Nas modificações de queries, o BM25 mantém a estabilidade da consulta quando termos são removidos, e adicionar termos ou trocar termos por outros similares porém mais específicos se mostraram técnicas capazes de melhorar a posição dos documentos relevantes no ranking. Por outro lado, o modelo Vetorial perde muito mais desempenho quando palavras são removidas da query. Trocar palavras por mais específicas não melhora o ranking em geral, apenas alterna documentos (comportamento vetorial característico que aproxima termos similares no espaço vetorial, garantindo um score próximo). Adicionar termos melhora a posição dos documentos relevantes.

Na análise de erros: 

- Para uma query do BM25, um documento irrelevante foi colocado no top 1 por ter maior frequência de tokens presentes na query e menor tamanho de documento. Além disso, o modelo falhou em dar relevância ao documento realmente relevância por não considerar termos semanticamente próximos (como "aerodynamics" e "flight").
- Para uma query do modelo vetorial, Um documento irrelevante foi colocado no top 1 por ter uma frequência maior dentre a mesma intersecção de termos para o top 2, que por sua vez é relevante. Além disso, termos semanticamente próximos no documento relevante foram ignorados (como "thermal" e "heat").
- Para o documento relevante omitido no modelo vetorial, a falha na recuperação se dá pela baixa intersecção de termos entre query e documento. Novamente, palavras semanticamente próximas foram ignoradas.

O principal motivo de erros é a falha dos dois modelos clássicos em considerar palavras semanticamente próximas às da query. Essa medida direta é prejudicial para a compreensão dos arquivos e, por sua vez, para a sua recuperação e ranking.
