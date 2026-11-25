Para a recuperação de documentos utilizando os modelos clássicos, criam-se as posting-lists a partir do dataset. Elas posteriormente são passadas aos modelos junto com a query, que por sua vez realizam a recuperação de documentos e retornam o ranking com IDs dos documentos, métricas, score e relevância.

A implementação optou por definir a Posting List, o Modelo Vetorial e Modelo Probabilístico e os Experimentos como classes. Como vários parâmetros e configurações são testados, é a melhor forma de simplificar e organizar o código.

O resto da implementação segue como funções simples divididas em documentos.

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
