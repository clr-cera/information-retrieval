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
      [Entrada máxima], [256 tokens (texto bruto, título + texto); *2.864 dos 3.633 documentos (78,8%) são truncados*, e 32,2% dos tokens da coleção ficam de fora],
      [Tempos], [109,7 s para os embeddings dos documentos (30 ms por documento); 0,16 s por consulta],
    )
  },
  caption: [Configuração da recuperação semântica.],
) <tab-semantic-config>

Os embeddings dos documentos são calculados uma vez e guardados em disco. Para cada consulta, gera-se o seu embedding e calcula-se o produto com a matriz de documentos (3.633 × 384); os 100 mais similares formam o ranking. A busca é exaustiva, como o enunciado permite. Com o truncamento (os documentos têm em média 357 tokens), o vetor de um documento longo representa só o título e o início do resumo. O modelo foi escolhido no dev pelo maior NDCG\@10: o `all-MiniLM-L6-v2` teve 0,3024, e o `multi-qa-MiniLM-L6-cos-v1`, 0,2718, mesmo lendo até 512 tokens.
