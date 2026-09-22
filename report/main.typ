#import "@preview/quill-assignment:0.1.0": *

#show: assignment.with(
  title: "Desenvolvimento e Análise de Modelos Claśsicos de Recuperação de Informação",
  course: "SCC0282 Recuperação de Informação",
  assignment: "Trabalho Prático 1",
  student: "Ariel Alves da Silva (8847378)\nStudent 2 (student2_id)",
  student-id: "8847378",
  university: "Universidade de São Paulo",
  date: datetime.today(),
  cover-page: true,
)

#outline()

= Introdução

Este trabalho consiste na implementação e análise de um sistema de Recuperação Textual utilizando dois modelos clássicos de recuperação da informação: modelo vetorial e modelo probabilístico. Ao analisar e comparar os dois modelos, é esperado obter uma distinção clara de classificação diante de uma base de dados real, fazendo uso de métricas exclusivas para avaliação de sistemas de Recuperação da Informação. 

O sistema consiste basicamente em 4 etapas:

+ Processamento de documentos
+ Criação de posting lists
+ Processamento de query
+ Aplicação de query em modelos de RI

Todas foram implementadas na linguagem Python.

= Técnicas utilizadas

== Tratamento de Documentos/Queries

Para um processamento adequado dos documentos e queries, foi escolhido o uso da biblioteca #link("https://www.nltk.org/")[NTLK (Natural Language Toolkit)] do Python, que possui ferramentas úteis para realizar o processamento, entre elas:

- Lista de stopwords
- Lematização
- Stemming

As funções de tokenização e normalização foram aplicadas em hard-code.

Também foram criadas 4 possibilidades de pipeline:

- *NoStopRemovalNoStemming* - Sem stop words, sem stemming 
- *NoStopRemovalWithStemming* - Sem stop words, com stemming
- *WithStopRemovalNoStemming* - Com stop words, sem stemming
- *WithStopRemovalWithStemming* - Com stop words, com stemming

== Posting Lists

A posting list (ou indíce invertido) é uma estrutura de dados que mapeia uma palavra específica para uma lista de documentos onde isto aparece, adicionado de informações opcionais.

Na implementação deste trabalho, a posting list é representada por uma classe que possui quatro mapeamentos:

+ *Postings* - Dicionário que mapeia termos para um dicionário de IDs que mapeia para a frequência do termo no documento
+ *Term Frequencies* - Dicionaŕio que mapeia termos para a frequência total na posting list (`tf`)
+ *Document Frequencies* - Dicionário que mapeia termos para o número de documentos em que aparecem (`df`)
+ *Document Lengths* - Dicionário que mapeia IDs para o número total de termos no documento

As funções públicas da classe são para resgatar informações concernentes a estes quatro dicionários.

== Modelo Probabilístico BM25

O modelo probabilístico BM25 consiste na seguinte função de ranqueamento:

$ "score"(d,q) = sum_(t in q) I D F(t)(t f(t, d)(k_1+1))/(t f(t, d)+k_1(1-b+(b(|d|)/"avgdl")) $

- $t f(t,d)$ - Frequência do termo no documento
- $k_1$ - Parâmetro de controle da saturação
- $b$ - Parâmetro de controle da influência do tamanho do documento
- $|d|$ - Tamanho do documento

Onde:

$ I D F(t) = log(1 + (N-n_t+0.5)/(n_t+0.5)) $
$ "avgdl" = 1/N sum_i^N |d_i| $

- $N$ = Quantidade total de documentos
- $n_t$ = Quantidade de documentos que contém o termo $t$
- $|d_i|$ = Tamanho do documento


A implementação desta função foi feita exatamente como descrito aqui, com uso das bibliotecas `math` e `numpy`. Sua implementação foi feita como classe, recebendo os seguintes parâmetros:

- Posting List - Instância da classe `PostingList`
- Pipeline Options - Seleção de modo de processamento das queries

== Modelo Vetorial

O modelo vetorial consiste na seguinte função de ranqueamento:

$ s i m(d,q) = (sum w_(d t)w_(q t))/(sqrt(sum w_(d t)^2)+sqrt(sum w_(d t)^2)) $

Onde:

$ w = cases(
	(1 + log(f(t))) dot log(N/n_t) ", se" f(t) > 0,
	0 ", se" f(t) = 0,
) $

- $f(t)$ - Frequência do termo no documento/query.

Para otimizar o tempo de execução do algoritmo, o vetor de pesos é montado utilizando somente os termos pertencentes à query, com valor igual a zero caso algum dos termos seja inexistente no documento. Assim, se existem `n` termos na query, o vetor de qualquer documento selecionado terá dimensionalidade `n`, assim como o vetor de pesos da query.

A implementação desta função foi feita exatamente como descrito aqui, com uso das bibliotecas `math` e `numpy`. Sua implementação foi feita como classe, recebendo os seguintes parâmetros:

- Posting List - Instância da classe `PostingList`
- Pipeline Options - Seleção de modo de processamento das queries

= Avaliação dos modelos

Ambos os modelos foram avaliados sob as seguintes condições:

- Para ambos, foram testados os 4 tipos de pipeline
- Para o modelo probabilístico, foram testadas as 9 combinações possíveis para os parâmetros $k_1$ e $b$

$ k_1 in {0.5,1.2,2.0} $
$ b in {0, 0.75, 1} $

As seguintes queries foram executadas:

+ Q1: what similarity laws must be obeyed when constructing aeroelastic models of aircraft
+ Q2: what are the aeroelastic problems associated with flight of high speed aircraft
+ Q3: what problems of transient heat conduction in composite slabs have been solved so far
+ Q4: what chemical kinetic mechanism is applicable to hypersonic aerodynamic problems
+ Q5: how can the aerodynamic performance of ground effect machines be calculated

== Avaliação quantitativa

Para realizar a avaliação quantitativa entre modelos, foram selecionadas as seguintes métricas: Precision\@10, Recall\@10, MAP\@10.


