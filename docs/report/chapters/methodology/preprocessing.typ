== Pré-processamento

=== Representação de documentos e consultas

Cada documento do NFCorpus possui os campos `title` e `text`. Conforme o enunciado, ambos são concatenados (separados por um espaço) para formar a representação do documento em *todos* os sistemas: lexical, semântico e reranking. Campos vazios são descartados antes da concatenação. Os identificadores de documentos e consultas do BEIR são mantidos como texto (por exemplo, `MED-10` e `PLAIN-68`).

As consultas recebem exatamente o mesmo pré-processamento dos documentos no sistema lexical, garantindo que os termos da consulta e os do índice estejam no mesmo espaço de representação.

=== Etapas do pipeline lexical

O pré-processamento do sistema lexical foi implementado em Python com a biblioteca NLTK (versão 3.10.3), reaproveitando o código do Trabalho Prático 1 (módulo `src/ir/lexical.py`, originalmente `document_processor.py`). As etapas, aplicadas nesta ordem, são:

+ *Tokenização:* o texto é dividido em espaços em branco e, de cada token, são mantidos apenas os caracteres alfanuméricos (`str.isalnum`).
+ *Normalização:* conversão para letras minúsculas.
+ *Remoção de stopwords:* lista de stopwords em inglês do NLTK.
+ *Stemming:* algoritmo de Porter (`nltk.stem.PorterStemmer`).

Ao final, cada documento é representado pelo dicionário de frequências de seus termos, que alimenta o índice invertido.

A tokenização remove a pontuação *dentro* das palavras, o que tem um efeito importante neste corpus biomédico: termos compostos por hífen ou barra são unidos em um único token. Os casos mais frequentes na coleção são `follow-up` → `followup`, `meta-analysis` → `metaanalysis`, `long-term` → `longterm`, `case-control` → `casecontrol` e `and/or` → `andor`. Com isso, uma consulta escrita como "meta analysis" (com espaço) não corresponde ao termo `metaanalysis` do índice. Esse tipo de divergência de vocabulário é justamente o que a busca semântica pode compensar, e é retomado na análise por consulta.

A lematização (WordNet, com etiquetagem morfossintática do NLTK) também está implementada no módulo, mas não foi incluída na grade de configurações avaliada no conjunto dev e, portanto, não é usada no sistema final.

=== Escolha do pipeline no conjunto dev

Foram avaliadas as quatro combinações de remoção de stopwords e stemming. A escolha foi feita *exclusivamente no conjunto dev* (324 consultas), junto com os parâmetros $k_1$ e $b$ do BM25, pelo maior NDCG\@10 médio (script `tune_lexical.py`). A @tab-preproc resume o efeito de cada pipeline sobre a coleção (3.633 documentos) e sobre o desempenho no dev.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (2.4fr, 1fr, 1fr, 1fr, 1.1fr, 1fr),
      align: (left, right, right, right, right, right),
      table.header(
        [*Stopwords / Stemming*], [*Vocabulário*], [*Postings*], [*Tam. médio doc.*], [*NDCG\@10 (padrão)*], [*Melhor NDCG\@10*],
      ),
      [Mantidas / sem stemming], [36.477], [465.539], [233,8], [0,2655], [0,2672],
      [Removidas / sem stemming], [36.351], [372.335], [155,0], [0,2713], [0,2725],
      [Mantidas / com stemming], [29.037], [443.244], [233,8], [0,2876], [0,2880],
      [*Removidas / com stemming*], [*28.942*], [*350.458*], [*155,0*], [*0,2906*], [*0,2916*],
    )
  },
  caption: [Efeito de cada pipeline de pré-processamento sobre a coleção (3.633 documentos) e sobre o NDCG\@10 médio no conjunto dev. "Tam. médio doc." é o número médio de termos por documento após o pré-processamento. "Padrão" usa os valores usuais do BM25 ($k_1 = "1,2"$; $b = "0,75"$) e "Melhor" é o maior valor na grade $k_1 in {"0,5"; "1,2"; "2,0"}$ × $b in {0; "0,75"; "1,0"}$.],
) <tab-preproc>

Os números mostram que as duas etapas atuam de formas diferentes:

- *Stemming* é a etapa de maior impacto no desempenho. Ele reduz o vocabulário em cerca de 20% (de 36.477 para 29.037 termos) ao agrupar variações morfológicas, e eleva o NDCG\@10 de 0,2655 para 0,2876 com os parâmetros usuais do BM25 (+0,022).
- *Remoção de stopwords* quase não altera o vocabulário (apenas 126 termos a menos), mas reduz o número de postings em cerca de 20% (de 465.539 para 372.335) e o tamanho médio dos documentos em 34% (de 233,8 para 155,0 termos). O ganho em NDCG\@10 é pequeno (+0,003 a +0,006), o que é esperado no BM25, cujo IDF já atribui peso baixo a termos que aparecem em quase todos os documentos. A principal vantagem é a redução do índice e, consequentemente, do custo de consulta.

A configuração selecionada foi *com remoção de stopwords e com stemming*, que obteve o maior NDCG\@10 no dev tanto com os parâmetros usuais do BM25 (0,2906) quanto na melhor combinação da grade (0,2916). Ela também é a mais compacta das quatro. Os parâmetros adotados no sistema final são os valores usuais do BM25, $k_1 = "1,2"$ e $b = "0,75"$ (NDCG\@10 = 0,2906 no dev); essa escolha é discutida na seção de busca lexical.

=== Características das consultas

As consultas de dev e test do NFCorpus são curtas: em média 3,3 tokens no test (3,4 no dev) antes do pré-processamento e 2,6 termos depois. Com tão poucos termos, a ausência de um único termo no vocabulário (por exemplo, por erro de digitação ou pela junção de termos com hífen) pode eliminar boa parte da informação da consulta. Uma consulta do dev fica sem nenhum termo após o pré-processamento e, portanto, não recupera nenhum documento no sistema lexical.

=== Pré-processamento nos demais componentes

- *Busca semântica e reranking:* os modelos neurais recebem o texto bruto (título + texto, sem remoção de stopwords nem stemming), pois usam o próprio tokenizador de subpalavras (WordPiece) e foram treinados sobre texto natural. Os limites de comprimento de entrada e o truncamento são discutidos nas seções correspondentes.
- *Correção ortográfica:* o dicionário é formado pelos termos da coleção *antes* do stemming e da remoção de stopwords (apenas tokenização e minúsculas), como exige o enunciado. Assim, as correções são sempre palavras reais da coleção, que depois passam pelo mesmo pipeline das demais consultas.

// TODO: a tokenização atual gera um token vazio ("") a partir de pontuação isolada (por exemplo, " - "):
// 6.109 ocorrências em 1.513 documentos, que são indexadas como um termo. Decidir se o código será corrigido
// (descartar tokens vazios) antes da execução final; se for, atualizar os números da tabela acima.
