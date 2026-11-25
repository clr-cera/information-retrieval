== Análise por consulta

Serão selecionadas 2 consultas para cada modelo onde o resultado foi claramente discrepante (de modo positivo). O pipeline utilizado foi o completo `WithStopRemovalWithStemming`. Os parâmetros utilizados para o modelo probabilístico foram $k=1.2$ e $b=1.0$.

=== Consultas com BM25 superior

Query 52: `what is the available information pertaining to the effect of slight
rarefaction on boundary layer flows (the ?slip? effect) .`

- BM25 MAP: 0.875
- Vetorial MAP: 0.12

1. Doc 326 [RELEVANT]
2. Doc 21 [RELEVANT]
3. Doc 306 [RELEVANT]
4. Doc 265 [IRRELEVANT]
5. Doc 1215 [IRRELEVANT]

#divider()

Query 146: `does a membrane theory exist by which the behaviour of pressurized
membrane cylinders in bending can be predicted .`

- BM25 MAP: 0.75
- Vetorial MAP: 0.24

1. Doc 1045 [RELEVANT]
2. Doc 955 [IRRELEVANT]:
3. Doc 1130 [IRRELEVANT]: 
4. Doc 840 [RELEVANT]: 
5. Doc 854 [IRRELEVANT]

As duas queries possuem termos técnicos precisos ou palavras-chave exatas.

=== Consultas com Modelo Vetorial superior

Query 133 : `experimental studies of creep buckling .`

- BM25 MAP: 0.23
- Vetorial MAP: 0.59

1. Doc 1019 [RELEVANT]
2. Doc 1016 [RELEVANT]
3. Doc 951 [IRRELEVANT]
4. Doc 1018 [RELEVANT]
5. Doc 1025 [IRRELEVANT]

#divider()

Query 167 : `exact solution methods for calculating the ablative mass loss of a
material ablating at high temperatures in a hypersonic flight
environment .`

- BM25 MAP: 0.41
- Vetorial MAP: 0.75

1. Doc 274 [RELEVANT]
2. Doc 1279 [IRRELEVANT]
3. Doc 908 [IRRELEVANT]
4. Doc 82 [RELEVANT]
5. Doc 576 [IRRELEVANT]

As duas queries associam conceitos, com proximidade temática ("creep buckling", "ablative mass losss").

=== Consultas com desempenho insatisfatório em ambos

Query 31 : `what size of end plate can be safely used to simulate two-dimensional
flow conditions over a bluff cylindrical body of finite aspect ratio .`

- BM25 MAP: 0.00074
- Vetorial MAP: 0.00077

1. Doc 751 [IRRELEVANT]:
2. Doc 1153 [IRRELEVANT]: 
3. Doc 1209 [IRRELEVANT]:
4. Doc 228 [IRRELEVANT]
5. Doc 1245 [IRRELEVANT]

#divider()

Query 22 : `did anyone else discover that the turbulent skin friction is not over
sensitive to the nature of the variation of the viscosity with
temperature .`

- BM25 MAP: 0.0010
- Vetorial MAP: 0.0017

1. Doc 125 [IRRELEVANT]
2. Doc 560 [IRRELEVANT]
3. Doc 254 [IRRELEVANT]
4. Doc 413 [IRRELEVANT]
5. Doc 307 [IRRELEVANT]


As duas consultas são longas e no formato de pergunta em linguagem comum ("what size of end plate...", "did anyone else...")
