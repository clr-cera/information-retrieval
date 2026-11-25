== Recuperação semântica

A recuperação semântica usa um *bi-encoder* pré-treinado, sem fine-tuning: consulta e documento são convertidos separadamente em vetores, e a relevância é a similaridade entre eles (`SemanticIndex`, `src/ir/neural.py`).

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (auto, 1fr),
      align: (left, left),
      table.header([*Item*], [*Valor*]),
      [Modelo e versão], [`sentence-transformers/all-MiniLM-L6-v2`, revisão `1110a243` do Hugging Face],
      [Biblioteca], [Sentence Transformers 6.3.0 (PyTorch 2.15.0, Transformers 5.23.0), em CPU],
      [Arquitetura], [Transformer MiniLM de 6 camadas + mean pooling + normalização L2],
      [Dimensão / similaridade], [384 / cosseno, calculado como produto escalar de vetores normalizados],
      [Entrada máxima], [256 tokens (subpalavras WordPiece); texto bruto, título + texto],
      [Tempo dos embeddings], [109,7 s para os 3.633 documentos (30 ms por documento)],
      [Tempo médio por consulta], [0,16 s (test)],
    )
  },
  caption: [Configuração da recuperação semântica.],
) <tab-semantic-config>

Os embeddings dos documentos são calculados uma vez, em lotes de 32, e guardados em disco. Para cada consulta, gera-se o seu embedding e calcula-se o produto com a matriz de documentos (3.633 × 384); os 100 mais similares formam o ranking. A busca é exaustiva, o que o enunciado permite para a busca semântica. Quase todo o tempo de consulta é a geração do embedding da consulta.

*Truncamento:* os documentos têm em média 357 tokens (10% passam de 504), acima do limite de 256. Assim, *2.864 dos 3.633 documentos (78,8%) são truncados*, e 32,2% dos tokens da coleção ficam fora dos embeddings: o vetor de um documento longo representa o título e o início do resumo.

O modelo foi escolhido no dev (`tune_semantic.py`) pelo maior NDCG\@10: `all-MiniLM-L6-v2` teve 0,3024, e `multi-qa-MiniLM-L6-cos-v1`, 0,2718. O segundo lê até 512 tokens e trunca só 330 documentos, mas foi pior; como os modelos também diferem nos dados de treinamento, não é possível isolar a causa.
