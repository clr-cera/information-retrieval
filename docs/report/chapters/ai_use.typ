Os modelos de embeddings, o cross-encoder e a LLM fazem parte do experimento e estão descritos na metodologia. Como *apoio ao desenvolvimento*, o grupo usou o Claude (pelo Claude Code) e o Deepseek (pelo opencode) em:

- *programação e depuração:* scripts de análise e de avaliação e a verificação dos arquivos de resultados;
- *organização* do repositório e da documentação;
- *revisão* de seções deste relatório;
- *verificação:* conferência de que o contexto enviado à LLM é exatamente o top-5 do ranking final, recalculando o pipeline para as 10 consultas do RAG;
- *apoio à avaliação do RAG:* uma ficha de evidências que compara as afirmações de cada resposta com os 5 documentos da consulta, sem notas. A ficha também embasou a escolha dos casos da análise de falhas;

Todas as escolhas experimentais foram alinhadas pelo grupo com base na especificação, e todos os integrantes são responsáveis por compreender o código, a metodologia e os resultados.
