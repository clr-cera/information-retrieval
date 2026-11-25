As técnicas se mostraram complementares, e cada uma falha de um jeito característico:

- *Lexical e semântico têm médias parecidas (NDCG\@10 de 0,3124 e 0,3167), mas acertam consultas diferentes.* O BM25 vence com termos técnicos raros (kohlrabi, cadaverine), e o bi-encoder, com variação de vocabulário e formas diferentes da mesma palavra (low-carb × low-carbohydrate, frozen × freezing). Muitas falhas vêm da *tokenização*: hífens que o índice lexical junta em um termo só e subpalavras compartilhadas por palavras de sentidos diferentes (grape × grapefruit, myelopathy × myeloma).
- *O RRF é a melhoria mais barata.* Com 0,07 ms por consulta, eleva o NDCG\@10 para 0,3440, porque os sistemas trazem relevantes diferentes. Ainda fica abaixo do melhor sistema de cada consulta (0,3795).
- *O reranking dá o melhor resultado* (NDCG\@10 de 0,3557 e MAP\@10 de 0,1382). Porém, melhora e piora quase o mesmo número de consultas (108 e 97) e custa cerca de 4 s por consulta em CPU.
- *A correção ortográfica é eficaz neste cenário:* corrigiu os 10 erros e recuperou todo o NDCG\@10 perdido (0,47 → 0,16 → 0,47).
- *No RAG*, ao menos um relevante chegou ao contexto em 9 das 10 perguntas, e o modelo só citou documentos enviados. No caso em que o RAG não ajudou, o problema estava na recuperação, e não na geração.

// TODO (grupo): completar com a conclusão da avaliação humana do RAG (médias por critério, sem RAG × com RAG).

As médias globais esconderam o essencial: foi a análise por consulta que explicou por que os sistemas acertam e erram. Como trabalhos futuros, ficam:

- tratar os hífens na tokenização lexical;
- usar um bi-encoder com entrada maior, já que 78,8% dos documentos são truncados;
- avaliar a robustez do sistema semântico a erros ortográficos.
