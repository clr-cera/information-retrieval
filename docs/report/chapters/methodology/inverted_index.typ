== Índice invertido

O índice invertido foi implementado do zero pelo grupo, na classe `PostingList` (`src/ir/lexical.py`), usando apenas dicionários nativos do Python. Nenhuma biblioteca de indexação ou de busca textual é usada: o índice é construído e consultado pelo próprio código do grupo.

=== Estruturas de dados

O índice guarda, para cada termo, a sua posting list e as estatísticas que o BM25 precisa. A @tab-index-structs resume as estruturas.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (1.3fr, 1.4fr, 2.3fr),
      align: (left, left, left),
      table.header([*Atributo*], [*Tipo*], [*Conteúdo*]),
      [`postings`], [`dict[termo, dict[doc_id, tf]]`], [Dicionário de termos; para cada termo, a posting list com a frequência do termo em cada documento ($t f$)],
      [`document_frequencies`], [`dict[termo, int]`], [Número de documentos que contêm o termo ($n_t$, usado no IDF)],
      [`term_frequencies`], [`dict[termo, int]`], [Frequência total do termo na coleção],
      [`document_lengths`], [`dict[doc_id, int]`], [Tamanho de cada documento $|d|$, em termos, após o pré-processamento],
      [`total_length`], [`int`], [Soma dos tamanhos de todos os documentos ($sum |d|$), usada para obter o $"avgdl"$],
    )
  },
  caption: [Estruturas do índice invertido (classe `PostingList`).],
) <tab-index-structs>

A escolha por tabelas hash (dicionários) dá acesso em tempo médio constante tanto ao termo no dicionário quanto a um documento dentro de uma posting list. As posting lists não precisam ser ordenadas por `doc_id`: o ranqueamento é feito termo a termo com acumuladores (descrito abaixo), e não há interseção ou união de listas como em uma busca booleana, que é o caso em que a ordenação seria necessária.

As estatísticas globais também ficam no índice: o número de documentos $N$ é o tamanho de `document_lengths` e o tamanho médio é $"avgdl" = "total_length" \/ N$. As duas são obtidas em $O(1)$, sem percorrer a coleção.

=== Construção

O índice é construído em uma única passagem pela coleção (método `add_documents`). Para cada documento, o texto (título + texto) passa pelo pré-processamento, que devolve o dicionário de frequências dos termos. Cada par (termo, frequência) é inserido por `_add_posting`, que, na mesma operação:

+ cria a posting list do termo, se ele ainda não existir no dicionário;
+ registra o $t f$ do termo no documento;
+ incrementa o $n_t$ do termo e a sua frequência total na coleção;
+ soma a frequência ao tamanho do documento e ao `total_length`.

Como o pré-processamento já agrega as ocorrências de cada termo por documento, cada par (termo, documento) é inserido uma única vez, e o $n_t$ é incrementado exatamente uma vez por documento.

=== Consulta

A consulta é processada *termo a termo, com acumuladores* (`ProbabilisticModel.execute_query`):

+ a consulta passa pelo mesmo pré-processamento dos documentos, e os termos fora do vocabulário são descartados;
+ para cada termo restante, o IDF é calculado a partir de $n_t$ e $N$;
+ a posting list do termo é percorrida, e a contribuição do BM25 de cada documento dela é somada ao acumulador desse documento, usando o $t f$ da posting list, o $|d|$ do documento e o $"avgdl"$ do índice;
+ os documentos com acumulador são ordenados pelo score.

Assim, *somente as posting lists dos termos da consulta são visitadas*. Documentos que não contêm nenhum termo da consulta nunca são acessados e não aparecem no ranking. Isso atende à exigência do enunciado de não percorrer toda a coleção a cada consulta.

Durante o trabalho, foi identificado que a primeira versão do BM25 (herdada do TP1) copiava os dicionários inteiros de $n_t$ e de tamanhos dos documentos e somava todos os tamanhos para obter o $"avgdl"$ em cada consulta. Ou seja, percorria os 3.633 documentos a cada busca. A versão final mantém o `total_length` no índice e lê as estatísticas diretamente, sem cópias. Os rankings e scores das duas versões foram comparados em todas as consultas de dev e test e são idênticos. Medidas lado a lado, nas mesmas condições, a versão final levou em média 0,9 ms por consulta, contra 3,3 ms da versão anterior.

=== Estatísticas do índice

A @tab-index-stats reúne as estatísticas exigidas pelo enunciado, medidas na execução final sobre o conjunto test (pipeline com remoção de stopwords e stemming; BM25 com $k_1 = "1,2"$ e $b = "0,75"$). As medições foram feitas em um notebook com processador AMD Ryzen 7 5700U e 14 GB de RAM, em execução sequencial (um único núcleo).

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (2.2fr, 1fr),
      align: (left, right),
      table.header([*Estatística*], [*Valor*]),
      [Documentos indexados], [3.633],
      [Termos no vocabulário], [28.942],
      [Total de postings], [350.458],
      [Tamanho médio de uma posting list], [12,1],
      [Tempo de construção do índice], [7,32 s],
      [Tempo médio de processamento de uma consulta (323 consultas)], [0,90 ms],
    )
  },
  caption: [Estatísticas do índice invertido e tempos medidos no conjunto test.],
) <tab-index-stats>

Quase todo o tempo de construção é do pré-processamento. Em uma medição separada, a tokenização, a remoção de stopwords e o stemming dos 3.633 documentos levaram 5,51 s, e a inserção no índice apenas 0,27 s. Os tempos variam entre execuções (em outra execução isolada do sistema lexical, a construção levou 5,95 s e a consulta média 0,56 ms); a tabela traz os valores da execução final do pipeline completo.

A distribuição das posting lists é muito desigual, como esperado pela lei de Zipf. A mediana é de apenas 1 documento: 57,9% dos termos (16.770) aparecem em um único documento. Já a maior lista, a do radical `studi` ("study", "studies"), cobre 2.358 documentos (65% da coleção).

O custo de cada consulta depende apenas do tamanho das posting lists dos seus termos. No test, as consultas têm em média 2,4 termos presentes no vocabulário, e cada consulta visita em média 558 postings (mediana de 192). Isso equivale a 0,16% dos 350.458 postings do índice. Em média, 485 documentos recebem score por consulta (mediana de 191), ou 13,3% da coleção.

Uma consequência dessa recuperação restrita aos documentos que contêm algum termo da consulta é que o ranking lexical pode ter menos de 100 documentos. No test, isso acontece em 134 das 323 consultas, e 16 consultas não recuperam nenhum documento porque nenhum de seus termos está no vocabulário (38 termos de consulta, no total, estão fora do vocabulário). Nesses casos, a busca híbrida recebe menos de 100 candidatos do sistema lexical, e o ranking semântico é o único que contribui para os documentos restantes.

// TODO: o vocabulário (28.942) inclui o termo vazio "", gerado pela tokenização a partir de pontuação isolada; ele
// tem a 5ª maior posting list (1.513 documentos). Se o código for corrigido, atualizar vocabulário, postings e tempos.
