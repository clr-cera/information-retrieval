As técnicas se mostraram complementares, e cada uma falha de um jeito característico:

- *Lexical e semântico têm médias parecidas (NDCG\@10 de 0,3124 e 0,3167), mas acertam consultas diferentes.* O BM25 vence com termos técnicos raros (kohlrabi, cadaverine), e o bi-encoder, com variação de vocabulário e formas diferentes da mesma palavra (low-carb × low-carbohydrate, frozen × freezing). Muitas falhas vêm da *tokenização*: hífens que o índice lexical junta em um termo só e subpalavras compartilhadas por palavras de sentidos diferentes (grape × grapefruit, myelopathy × myeloma).
- *O RRF é a melhoria mais barata.* Com 0,07 ms por consulta, eleva o NDCG\@10 para 0,3440, porque os sistemas trazem relevantes diferentes. Ainda fica abaixo do melhor sistema de cada consulta (0,3795).
- *O reranking dá o melhor resultado* (NDCG\@10 de 0,3557 e MAP\@10 de 0,1382). Porém, melhora e piora quase o mesmo número de consultas (108 e 97) e custa cerca de 4 s por consulta em CPU.
- *A correção ortográfica é eficaz neste cenário:* corrigiu os 10 erros e recuperou todo o NDCG\@10 perdido (0,47 → 0,16 → 0,47).
- *No RAG*, ao menos um relevante chegou ao contexto em 9 das 10 perguntas, e o modelo só citou documentos enviados. Sem RAG, três respostas contradizem os documentos em afirmações centrais; com RAG, as afirmações podem ser rastreadas às fontes, com imprecisões pontuais. O ganho foi maior quando o contexto tinha boa evidência (PLAIN-2750) e pequeno quando o modelo já sabia a resposta (PLAIN-270). No caso em que o RAG não ajudou, o problema estava na recuperação, e ainda assim ele evitou afirmar algo falso, comparado a resposta sem RAG.
- *Na avaliação humana*, o RAG elevou a fidelidade de 0,60 para 2,00 e deu rastreabilidade máxima (2,00), mas quase não mudou a completude (1,70 → 1,90) e não mudou a utilidade (1,80 nos dois casos). As respostas sem RAG são diretas e parecem úteis, mas não dá para verificá-las, e várias contradizem a evidência. Com RAG, a resposta fica presa ao contexto: é fiel e verificável, mas responde menos quando o contexto não traz a informação.

As médias globais não mostram os motivos das falhas. Foi a análise por consulta que explicou por que os sistemas acertam e erram. Como trabalhos futuros, ficam:

- tratar os hífens na tokenização lexical;
- usar um bi-encoder com entrada maior, já que 78,8% dos documentos são truncados;
- avaliar a robustez do sistema semântico a erros ortográficos.
