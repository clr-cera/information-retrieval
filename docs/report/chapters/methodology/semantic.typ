== Recuperação semântica

A recuperação semântica usa um modelo pré-treinado com arquitetura *bi-encoder*: consulta e documento são convertidos, separadamente, em vetores densos (embeddings), e a relevância é a similaridade entre os vetores. A implementação está na classe `SemanticIndex` (`src/ir/neural.py`). Nenhum modelo foi treinado ou ajustado (fine-tuning).

=== Modelo e configuração

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (auto, 1fr),
      align: (left, left),
      table.header([*Item*], [*Valor*]),
      [Modelo], [`sentence-transformers/all-MiniLM-L6-v2`],
      [Versão], [revisão `1110a243fdf4706b3f48f1d95db1a4f5529b4d41` do Hugging Face],
      [Biblioteca], [Sentence Transformers 6.3.0 (com PyTorch 2.15.0 e Transformers 5.23.0)],
      [Arquitetura], [Transformer MiniLM de 6 camadas, seguido de *mean pooling* e normalização L2],
      [Dimensionalidade], [384],
      [Função de similaridade], [cosseno, calculado como produto escalar entre vetores normalizados],
      [Normalização], [L2 (`normalize_embeddings=True`): todos os vetores têm norma 1],
      [Comprimento máximo de entrada], [256 tokens (subpalavras WordPiece, incluindo os tokens especiais)],
      [Representação do documento], [título + texto, sem pré-processamento lexical],
      [Execução], [CPU (AMD Ryzen 7 5700U, 8 threads do PyTorch), sem GPU],
    )
  },
  caption: [Configuração da recuperação semântica.],
) <tab-semantic-config>

Os modelos neurais recebem o texto bruto, sem remoção de stopwords nem stemming, porque usam o próprio tokenizador de subpalavras e foram treinados sobre texto natural. Termos raros são divididos em pedaços conhecidos pelo modelo (por exemplo, `ergothioneine` vira `er`, `##go`, `##thi`, `##one`, `##ine`), de modo que nenhum termo fica fora do vocabulário, ao contrário do que acontece no índice invertido.

=== Indexação e busca

Os embeddings dos 3.633 documentos são calculados uma única vez, em lotes de 32, e guardados em disco (`data/embeddings/`), junto com a ordem dos documentos e os metadados do modelo. Nas execuções seguintes, a matriz é lida do disco, desde que o modelo, a dimensão, a normalização e a lista de documentos sejam os mesmos.

Para cada consulta, o modelo gera o embedding da consulta, e a similaridade com todos os documentos é obtida por um único produto entre a matriz de embeddings (3.633 × 384) e o vetor da consulta. Os 100 documentos de maior similaridade formam o ranking semântico. A busca é exaustiva, o que o enunciado permite para a busca semântica dada a dimensão da coleção.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1fr, auto),
      align: (left, right),
      table.header([*Medida*], [*Valor*]),
      [Tempo para gerar os embeddings dos 3.633 documentos], [109,7 s (30 ms por documento)],
      [Tempo médio de processamento de uma consulta (test, 323 consultas)], [0,16 s],
    )
  },
  caption: [Tempos da recuperação semântica, em CPU.],
) <tab-semantic-times>

O tempo de geração dos embeddings foi medido em uma execução isolada, na mesma máquina; os vetores obtidos foram idênticos aos do cache usado nos experimentos. Quase todo o tempo de uma consulta é gasto para gerar o embedding da própria consulta; a multiplicação pela matriz dos documentos é desprezível em comparação.

=== Truncamento

O modelo processa no máximo 256 tokens; o restante do texto é descartado e não influencia o embedding. Os documentos do NFCorpus são mais longos do que isso: têm em média 357 tokens (mediana de 357; 10% passam de 504; o maior tem 2.377). Assim, *2.864 dos 3.633 documentos (78,8%) são truncados*, e 32,2% de todos os tokens da coleção ficam de fora dos embeddings. Na prática, o embedding de um documento representa o título e a parte inicial do resumo. Essa limitação é considerada na análise por consulta.

=== Escolha do modelo no dev

Foram avaliados dois bi-encoders da biblioteca Sentence Transformers no conjunto dev (script `tune_semantic.py`), escolhendo o de maior NDCG\@10 médio.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1.6fr, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      table.header([*Modelo*], [*NDCG\@10*], [*P\@10*], [*Máx. de tokens*], [*Docs. truncados*]),
      [`all-MiniLM-L6-v2`], [*0,3024*], [0,2401], [256], [2.864],
      [`multi-qa-MiniLM-L6-cos-v1`], [0,2718], [0,2170], [512], [330],
    )
  },
  caption: [Comparação dos bi-encoders no conjunto dev (324 consultas). Ambos geram vetores de 384 dimensões.],
) <tab-semantic-dev>

O `all-MiniLM-L6-v2` foi escolhido. Vale notar que o `multi-qa-MiniLM-L6-cos-v1`, que lê até 512 tokens e quase não trunca documentos, foi pior no dev: ler o documento inteiro não compensou a diferença entre os modelos. Como os dois diferem tanto no limite de tamanho quanto nos dados de treinamento, os experimentos não permitem isolar a causa.
