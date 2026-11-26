Os modelos de embeddings, o cross-encoder e a LLM fazem parte do experimento e estão descritos na metodologia. Como *apoio ao desenvolvimento*, o grupo usou o Claude (pelo Claude Code) e o Deepseek (pelo opencode) em:

- *programação e depuração:* scripts de análise e de avaliação, o experimento de RAG, a verificação dos arquivos de resultados, a correção da consulta do BM25 para não percorrer a coleção e o download alternativo do dataset;
- *organização* do repositório e da documentação;
- *análise:* levantamento de estatísticas e verificação, nos dados, das hipóteses usadas nas explicações;
- *redação e revisão* de seções deste relatório e do material de estudo para a defesa (`docs/explanation/`);
- *verificação:* conferência de que o contexto enviado à LLM é exatamente o top-5 do ranking final, recalculando o pipeline para as 10 consultas do RAG;
- *apoio à avaliação do RAG:* uma ficha de evidências que compara as afirmações de cada resposta com os 5 documentos da consulta, sem notas e sem indicar a condição. A ficha também embasou a escolha dos casos da análise de falhas;
- *segunda avaliação do RAG:* as notas usadas para medir a concordância foram dadas pelo Claude, como avaliador LLM declarado (seção de resultados do RAG). As notas finais são as da avaliação humana, feita por uma integrante do grupo.

Todas as escolhas experimentais foram conferidas pelo grupo, e todos os integrantes são responsáveis por compreender o código, a metodologia e os resultados.
