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

- *NoStopRemovalNoStemming* - Sem remoção de stop words, sem stemming 
- *NoStopRemovalWithStemming* - Sem remoção stop words, com stemming
- *WithStopRemovalNoStemming* - Com remoção de stop words, sem stemming
- *WithStopRemovalWithStemming* - Com remoção de stop words, com stemming

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

== Comparação entre Modelo Vetorial e Modelo Probabilístico

Para realizar a comparação entre os dois modelos, o modelo probabilístico recebeu parâmetros fixos $k=1.2$ e $b=1.0$. As métricas utilizadas para comparação foram Precision, Recall e MAP.


=== Curva Precision x Recall

Na curva do gráfico Precision x Recall, cada ponto representa um top-k, com P\@k e R\@k definidos como a média de todas as queries executadas.

#figure(image("../src/plots/precision_vs_recall_all_groups_combined.png", width: 100%))

Analisando a figura, é fácil averiguar que, em todos os casos, *o modelo probabilístico foi superior ao vetorial* com uma boa margem entre o pior do modelo probabilístico e o melhor do modelo vetorial (cerca de 5%).

Para o modelo *probabilístico*, existem duas duplas de grupos semelhantes: `WithStopRemovalWithStemming` e `NoStopRemovalWithStemming` apresentaram desempenho semelhante e claramente superior a `WithStopRemovalNoStemming` e `NoStopRemovalNoStemming` (também semelhantes). Isso evidencia que o tratamento de strings que afeta mais positivamente o modelo é a aplicação do stemming. Ao final da curva, é possível ver que a remoção de stop words forneceu uma pequena vantagem de modo geral.

Para o modelo *vetorial*, também existem duas duplas de grupos semelhantes, mas comportamento inverso: `WithStopRemovalWithStemming` e `NoStopRemovalNoStemming` foram superiores a `WithStopRemovalNoStemming` e `NoStopRemovalWithStemming`. Isso evidencia que, no modelo vetorial, o tratamento mais significativo é a remoção de stop words. O stemming fornece apenas uma pequena vantagem de modo geral.

Pela análise da curva Precision x Recall, pode-se concluir que:

- No modelo *probabilístico*, o tratamento mais relevante é o stemming. A remoção de stop words possui baixa relevância, sendo mais decisivo nos primeiros resultados e se tornando quase inperceptível nos resultados posteriores.
- No modelo *vetorial*, o tratamento mais relevante é a remoção de stop words. O stemming possui baixa relevância, mas ainda assim é um fator discrepante ao longo de toda a curva.

Através dessas afirmações, pode-se inferir a causa.

No modelo *probabilístico*, a variação pequena ao alternar a aplicação da remoção de stop words evidencia que o modelo lida muito bem com palavras que se repetem em quase todos os arquivos, conseguindo reduzir sua relevância ao nível esperado. Isto provavelmente se deve ao parâmetro de penalização por *tamanho do documento*. 

Já a grande variação na presença do stemming pode transparecer um defeito: O modelo é facilmente influenciável pela frequência dos termos, ganhando eficiência quando os termos são agrupados ("andar", "andou", "andei" -> "and"), o que retira a influência de termos únicos. Para testar essa hipótese, foi aplicado `log` aos termos de frequência da equação do BM25, de modo que:

$ "score"(d,q) = sum_(t in q) I D F(t)(log(1+t f(t, d))(k_1+1))/(log(1+t f(t, d))+k_1(1-b+(b(|d|)/"avgdl")) $

#figure(image("../src/plots/precision_vs_recall_bim25_modified_all_groups_combined.png", width: 100%))

O desempenho do BM25 diminuiu. Mas note que a divisão em duplas por presença de stemming já praticamente não existe mais: os desempenhos se aproximaram, de modo que apenas stemming e apenas remoção de stop words apresentaram desempenho próximo a partir de k=5. Isso confirma a sensibilidade do BM25 a termos muito frequentes no documento, mas também mostra que essa sensibilidade é necessária para sua eficiência.

No modelo *vetorial*, a variação pequena ao alternar a aplicação de stemming pode evidenciar um ponto forte do modelo: Quanto a frequência das palavras no documento correlatas à query aumenta muito, o modelo lida bem com isso. Diferente de stop words, palavras com stemming se aproximam e identificam melhor documentos com temas específicos ("medicar", "medicando", "medicamento" -> "medic"). Isso não é tratado pelo *IDF*, mas sim pelo logaritmo que amortece a influência da frequência do termo no peso final.

Já a grande variação ao alternar a remoção de stop words transparece um defeito do modelo vetorial: Como stop words são muito comuns entre query e documento, o vetor de ambos começa a ficar poluído e com ruídos, piorando drasticamente a acurácia do modelo devido a dimensões extras desnecessárias. Isto provavelmente é uma falha da similaridade por cosseno, apesar do termo de controle *IDF*.

=== Comparação de MAP

Em ordem decrescente, as pontuações MAP para as variações do modelo probabilístico e vetorial se encontram no gráfico abaixo.

#figure(image("../src/plots/probabilistic_vs_vectorial_map.png", width: 100%))

Novamente, o modelo probabilístico se mostra superior ao modelo vetorial.

No modelo probabilístico, o stemming se mostrou como mais relevante no incremento do MAP do que a remoção de stop words.

Já no modelo vetorial, a remoção de stop words se mostrou como mais relevante no incremento do MAP do que o stemming, mas com menor discrepância do que no modelo probabilístico.

O comportamento observado na curva de Precision x Recall se repete no MAP, fortalecendo as hipóteses apresentadas.

== Análise por consulta

Serão selecionadas 2 consultas para cada modelo onde o resultado foi claramente discrepante (de modo positivo).

=== Consultas com BM25 superior

Query 52: `what is the available information pertaining to the effect of slight
rarefaction on boundary layer flows (the ?slip? effect) .`

- BM25 MAP: 0.875
- Vetorial MAP: 0.1207943404634581

1. Doc 326 [RELEVANT]
```
forst-order slip effects on the compressible laminar
boundary layer over a slender body of revolution in
axial flow .
analysis of the
compressible boundary layer with transverse curvature in first
order slip flow .  no boundary-layer interaction effects are considered
and only the zero pressure-gradient case is examined .
```

2. Doc 21 [RELEVANT]
```
on heat transfer in slip flow .
a number of authors have considered the effect of slip on the heat
transfer and skin friction in a laminar boundary layer over a flat plate .
reference 1 considers this by a perturbation on the usual laminar
boundary-layer analysis while some other studies.dash e.g., reference
the impulsive motion of an infinite plate .
```

3. Doc 306 [RELEVANT]
```second approximation to laminar compressible boundary
layer on flat plate in slip flow .
  the first-order solution for the laminar compressible boundary-layer
flow over a flat plate at constant wall temperature is given .  the
effect of slip at the wall as well as the interaction between the
boundary-layer flow and the outer stream flow are taken into
consideration .  the solution is obtained explicitly in terms of the known zero
order, or continuum, solution .  no
assumptions regarding the prandtl
number or viscosity-temperature law need be made .  it is found that the
first-order solution gives a decrease in heat transfer and, for
supersonic flow, an increase in skin friction .
for subsonic flow there is no
first-order shear effect .  the change in heat transfer is due to slip
and the change in friction is due to the interaction of the zero- and
first-order velocities at the outer edge of the boundary layer .
```

4. Doc 265 [IRRELEVANT]
```
some instabilities arising from the interaction between
shock waves and boundary layer .
  a brief review is made of the available information concerning
the flow fluctuations and instabilities arising from shock-induced
separation in the flow over aerofoils and wings .  the influence this
phenomenon has on the oscillatory behaviour of aerofoils and control
surfaces is also briefly discussed .
  a more detailed consideration is devoted to a recent investigation
at the n.p.l. into the part played by shock-induced separation in the
instability of a control surface .
```

5. Doc 1215 [IRRELEVANT]
```
the effect of slip particularly for highly cooled walls .
  it is found that for boundary conditions on the velocity slip
and on the temperature jump which are not oversimplified in an
unrealistic way, the effect of these phenomena on the heat transfer
and the shear at a stagnation point is of the order of the ratio of
the mean free path outside the boundary layer to the
boundary-layer thickness, even for highly cooled walls .  a simplified
theory of this effect is given, which puts the physical reasons for
the results in evidence and agrees closely with the more accurate
calculations .  it is concluded that the effects of slip and jump
are not negligible in comparison with other low-reynolds-number
corrections, even for very cold walls .
```

#divider()

Query 146: `does a membrane theory exist by which the behaviour of pressurized
membrane cylinders in bending can be predicted .`

- BM25 MAP: 0.75
- Vetorial MAP: 0.24285714285714285

1. Doc 1045 [RELEVANT]
```
the bending strength of pressurized cylinders .
  discussion of previously presented experimental data for the
loading of pressurized cylinders, in terms of membrane theory .
```

2. Doc 955 [IRRELEVANT]:
```
the membrane approach to bending instability of pressureized
cylindrical shells .
  recent theoretical and experimental
research is briefly described
to trace the development of deformation
and the occurrence of collapse in
pressurized circular cylindrical membranes
under applied moment loading .
the collapse of pure membrane cylinders
is then compared with instability
of pressurized cylindrical shells .
this approach leads to a better
understanding of the behavior of pressurized
cylinders under bending loads .
the results suggest possibilities for
further research utilizing the
membrane approach .
```

3. Doc 1130 [IRRELEVANT]: 
```
handbook of structural stability . pt .vi . strength
of stiffened curved plates and shells .
  a comprehensive review of failure
of stiffened curved plates and
shells is presented .
  panel instability in stiffened
curved plates and general instability
of stiffened cylinders are discussed .
the loadings considered for the
plates are axial, shear, and the
combination of the two .  for the
cylinders, bending, external pressure,
torsion, transverse shear, and
combinations of these loads are considered .
  general instability in stiffened
cylinders was investigated .  for
bending and torsion loads, test data
and theory were correlated .  for
external pressure several existing
theories were compared .  as a result
of this investigation a unified theoretical
approach to analysis of
general instability in stiffened cylinders
was developed .
```

4. Doc 840 [RELEVANT]: 
```
analysis of partly wrinkled membrane .
  a theory is derived to predict the stresses and deformations of
stretched-membrane structural components for loads under which part of
the membrane wrinkles .  rather than studying in detail the deformations
in the wrinkled region, the present theory studies average displacements
of the wrinkled material .  specific solutions of problems in flat and
curved membranes are presented .  the results of these solutions show
that membrane structures retain much of their stiffness at loads
substantially above the load at which wrinkling first occurs .
```

5. Doc 854 [IRRELEVANT]
```
boundary-value problems of the thin-walled circular
cylinder .
  the homogeneous differential equations of donnell's
theory of thin cylindrical shells are integrated .
expressions are obtained in closed form for the displacements,
membrane stresses, moments, and shear forces .
```

=== Consultas com Modelo Vetorial superior

Query 133 : `experimental studies of creep buckling .`

- BM25 MAP: 0.22897364073834656
- Vetorial MAP: 0.5885462880804495

1. Doc 1019 [RELEVANT]
```
note on creep buckling of columns .
  a method for estimating allowable
load capacities of columns subject
to creep is presented .  the method,
which utilizes approximate stress
distributions derived from
isochronous-stress-strain curves to estimate
column load capacities, is shown to
be conservative for the time for which
the estimate is made .
  an application of the method is
made to test data on as-received and
on stabilized 24s-t4 aluminum alloy .
a comparison of the computed column
capacities with experimental capacities
indicates that the method is
satisfactory for estimating the decrease in
capacity with increasing time .
  easily obtained, time-dependent
tangent-modulus loads are discussed .
they are interpreted as being approximations
to allowable load-capacity
estimates .  a limited application is made to
test data, and the results
appear promising .  it is concluded that if
certain limitations are recognized,
the method may prove to be useful because
of its simplicity .
  a presentation of the results of an
experimental investigation of the
effects of column imperfection and
column-material variation is made .  it
is found that column-capacity variations of
the order of 10 per cent can
result from column-imperfection differences
and column-material variation .
  the results of an experimental study of
the variation of column
capacity with temperature of exposure are presented .
they indicate that column
efficiency, as measured by decrease in capacity,
can be acceptable for very
short times at the higher temperatures .  the
efficiency at these higher
temperatures falls rapidly, however, with increasing time .
```

2. Doc 1016 [RELEVANT]
```
principles of creep buckling weight-strength analysis .
  the relation of the time-dependent tangent-modulus
load--as conceived by shanley--to actual column capacity
is clarified .  it may be interpreted as a limiting case of the
conservative estimate .  the time-dependent
tangent-modulus load is, therefore, an approximation to a
conservative estimate .  the approximation, however, may
be either conservative or nonconservative when applied
to imperfect or real columns .  typical cases are discussed
and experimental results for two alloys are cited .
```

3. Doc 951 [IRRELEVANT]
```
a unified theory of creep buckling under normal loads .
  a general theory of creep buckling, with the initial
imperfection as a parameter, is developed for the case of normal loading .
a hyperbolic-sine law is used to describe the process of creep .  the
theory is believed to be applicable to, among other structures,
columns, tubes, and possibly conical shells .  the wall of the
structure is idealized as a sandwich in order to simplify the
integration of the equations .
  experimental data on columns and tubes, from two different
sources, are compared with the predictions of the theory .
```

4. Doc 1018 [RELEVANT]
```
note on creep buckling of columns .
  the results of short-time elevated-temperature creep tests of
objective of obtaining procedures for predicting column lifetime .
semiempirical lifetime curves are obtained with the aid of a previously
published column creep theory and are used for deriving column curves .
the semiempirical lifetime curves are also used to study the effect of
varying applied stress and out-of-straightness .  in the range
considered, small variations in out-of-straightness are found to be of
little practical significance,. whereas, small stress variations change
the column lifetime considerably .  for the range of out-of-straightness
encountered in the tests, the data can be presented in plots that do not
explicitly include out-of-straightness, and plots of this type should be
satisfactory for predicting column lifetime for design purposes .
```

5. Doc 1025 [IRRELEVANT]
```
note on creep buckling of columns .
  the creep of a slightly crooked section column carrying a
constant load is studied theoretically .  the material of the
column is characterized by a strain-time relationship, under
constant uniaxial stress, of the form, where is
the total strain, is the constant stress, is the time, and e,a,b,
and k are material constants .  this form was selected because it
applies to at least two alloys--75s-t6 aluminum alloy at 600 f .
and a low-alloy steel at 800 and 1,100 f .  however, the
analysis is intended for any material having creep properties of the
same form and for which the material constants are known .  a
strain-time relationship under variable uniaxial stress, necessary
for the column analysis, is formulated from the constant-stress
properties with the aid of shanley's engineering hypotheses of
creep .
  the analysis leads to the conclusion that the lateral deflection
approaches infinity--that is, the column collapses--in finite time .
results are given showing the maximum length of time the
column can support a given load before it collapses and the growth
of stresses, strains, and deflections prior to collapse .
```

#divider()

Query 167 : `exact solution methods for calculating the ablative mass loss of a
material ablating at high temperatures in a hypersonic flight
environment .`

- BM25 MAP: 0.41666666666666663
- Vetorial MAP: 0.75

1. Doc 274 [RELEVANT]
```
analysis of quartz and teflon shields for a particular
re-entry mission .
  the transient performance of
ablation type heat protection shields is
treated herein for the surface of
a vehicle returning from outer space to the
earth .  the vehicle weighs 8640 kg,
has a ballistic factor of 500 lb ft,
re-enters with a speed of 11 km sec at
ratio of 0.5, and is subjected to a
maximum deceleration of 7.7 times the
gravity constant .
  by use of well known equations
for the heat transfer and the mass
transfer at a heated surface, a numerical
calculation method is derived which, for
the investigated ablation processes,
yields exact transient solutions of the
fundamental system of partial differential
equations .  the method is applied
to various quartz shields and to one
teflon shield, which all evaporate so
readily under the conditions of the
problem at hand that practically no flow
of molten shield material exists .
the solutions also show comparatively small
temperature changes parallel to the surface .
  the results show that the nose
of the vehicle is cooled predominantly by
the evaporation of the quartz or the
teflon,. the rest of the vehicle's surface
is cooled by radiation of the quartz
or evaporation of the teflon .  the large
mass transfer effects on the nose of
the vehicle are detrimental since the
resulting low surface temperatures prevent
the radiative heat transfer out of
the shield, which does not involve any
mass loss, from being the desirable
governing cooling factor .
```

2. Doc 1279 [IRRELEVANT]
```
sublimation in a hypersonic environment .
  a priori knowledge of the response of materials subjected to a
severe aerothermal environment is essential in the space age .
the successful design of space and re-entry vehicles demands
that the fundamental problem of the interaction between a
material and dissociated air be properly formulated and solved .  in
this paper, the problem of sublimation in a hypersonic
environment is considered .
  in this study of hypersonic ablation, the pertinent
conservation equations are derived and the simultaneous processes of
diffusion, convection, and thermal exchange are analyzed for the
vaporization of a refractory material which is subjected to the
environmental conditions encountered during hypersonic
reentry .
  for simplicity, only the forward stagnation point of an axially
symmetric body is treated .  it is shown that the quantity,
called the effective heat of vaporization, which includes all heat
absorbing or heat blocking effects, is an increasing function of
flight speed, independent of body size, except where
nonequilibrium vaporization effects or radiative effects appear .
```

3. Doc 908 [IRRELEVANT]
```
random vibration .
  random vibration is vibration which results
from an excitation which is not well represented by any simple
function (sinusoid, step, etc.) or any simple combination of
such functions but which is satisfactorily modeled by a
stochastic process .  it is perhaps not too much of an exaggeration
to say that /all vibration is random vibration ./  every
vibration record contains /hash/ at some level .  nevertheless,
until recently, engineering vibration theory has been able to
get along without including the consideration of random
excitations .
  now in several fields simultaneously there has occurred a
burst of activity in the application of random processes .  the
response of aircraft to buffeting from atmospheric turbulence
and the response of ships to confused seas have been put on
reasonably firm footing .  possibly the most dramatic problems
have been posed by the development of large jet and rocket
engines which produce spectacular amounts of random
vibrational energy .  the high level of random vibration in a jet
plane or a missile provides a severe environment with respect
to fatigue failure of structural members and with respect to
malfunctions of sensitive equipment .
```

4. Doc 82 [RELEVANT]
```
theoretical investigation of the ablation of a glass-type
heat protection shield of varied material properties
at the stagnation point of a re-entering irbm .
  the melting-type heat protection at the stagnation point of a
re-entering irbm is treated by employing homogeneous, opaque, and
nondecomposing glass shields which do not exceed a temperature of
some effects due to variations of the glass properties .  the ballistic
re-entry vehicle has a nose diameter of 0.635 m, a ballistic factor
of 3.5 x 10, a re-entry angle of 124.9 (from the
vertical) at an altitude of 100 km, and a re-entry speed of 4.5 .
the performance of 36 different glass shields with assumed
combinations of material properties is investigated by employing a
calculation method which yields practically exact, transient solutions
for the problem .  as a corollary, results for a certain steady flight
state are also given .  the discussions made it possible to derive
under realistic flight conditions some thermal characteristics for the
employment of thin, or light-weight, glass shields .
  investigation of these hypothetical glass shields leads to the
conclusion that a low thermal conductivity and a high specific heat,
and thus, a small thermal diffusivity are most desirable .  a small
thermal diffusivity yields high surface temperatures, causing a high
radiative heat transfer out of the shield,. and steep temperature
profiles normal to the surface, causing a small thermal penetration across
the shield with little total ablation of the shield .  results show that
for the assumed irbm re-entry, the necessary thickness of the employed
glass shields increases monotonically with thermal diffusivity which is
the only material parameter affecting this thickness .
  a high viscosity level and a high emissivity constant of the
surface of the supposedly opaque shield are also desirable,. although,
these two properties exert a comparatively small influence on the
overall performance when disregarding glass shields with an extremely
low viscosity level .
```

5. Doc 576 [IRRELEVANT]
```
viscous and inviscid stagnation flow in a dissociated hypervelocity free
 stream .
high reynolds number hypersonic stagnation flow over a blunt-nosed body
in a nonequilibrium dissociated free stream is analyzed and compared to
a similar flow in an initially undissociated ambient gas . free stream
dissociation effects on various equilibrium stagnation flow properties
in air are presented as a function of the ambient atom mass fraction and
 dissociation energy for velocities ranging from 15,000 to 25,000 fps .
significant changes in the bow shock geometry, stagnation gas state, and
 boundary layer behavior are found when the free stream dissociation
involves more than 10( of the total energy . it is observed that for
large amounts of both atomic oxygen and nitrogen ahead of the body, the
equilibrium shock layer properties converge toward those pertaining to
chemically and vibrationally-frozen flow across the bow shock .
moreover, under certain conditions, the ionization level can be increased by
 an order of magnitude and the usual reduction in frozen boundary layer
heat transfer due to a highly-cooled noncatalytic surface can increase
from stall of adjacent stages .
the effects of compromises of stage matching to favor part-speed
operation were also considered . this phase of the study indicated that
such compromises would severely reduce the complete-compressor-stall
margin . furthermore, the low-speed stage stall problem is transferred
from the inlet stages to the middle stages, which are more susceptible
to abrupt-stall characteristics .
the analysis indicates that inlet stages having continuous performance
characteristics at their stall points are desirable with respect to
part-speed compressor performance . these characteristics must, however,
 be obtained when the stages are operating in the flow environment of
the multistage compressor . alleviation of part-speed operational
problems may also be obtained by improvement in either stage flow range or
stage loading margin .
the results of this analysis are only qualitative . the trends obtained,
 however, are in agreement with those obtained from experimental studies
 of high-pressure-ratio multistage axial-flow compressors, and the
results are valuable in developing an understanding of the off-design
problem . in addition to these stage-matching studies, a general
discussion of variable-geometry features such as air bleed and adjustable
 gas model . numerical solutions of non-equilibrium airflows with fully
coupled chemistry provide a preliminary verification of such scaling for
benser, w.a.
limit characteristics . the analysis indicated that all these problems
could be attributed to discontinuities in the performance
characteristics of the front stages . such discontinuities can be due to the type
 of stage stall or to a deterioration of stage performance resulting
blades is included .
```

=== Consultas com desempenho insatisfatório em ambos

Query 31 : `what size of end plate can be safely used to simulate two-dimensional
flow conditions over a bluff cylindrical body of finite aspect ratio .`

- BM25 MAP: 0.000741839762611276
- Vetorial MAP: 0.0007668711656441718

1. Doc 751 [IRRELEVANT]:
```
a note on the use of end plates to prevent three dimensional
flow at the ends of bluff cylinders .
  the results are given of
some observations of the effects of
end plates on the three-dimensional
separated flow at the ends of
cylindrical models .  while these are
by no means exhaustive, it is felt
that they are of sufficient interest
to merit putting on record .
```

2. Doc 1153 [IRRELEVANT]: 
```
a study of the simulation of flow with free stream mach number 1 in a
choked wind tunnel .
the degree to which experimental results obtained under choking
conditions in a wind tunnel with solid walls simulate those associated with
an unbounded flow with free-stream mach number 1 is investigated for the
 cases of two-dimensional and axisymmetric flows . it is found that a
close resemblance does indeed exist in the vicinity of the body, and
that the results obtained in this way are generally at least as accurate
 as those obtained in a transonic wind tunnel with partly open test
section . some of the results indicate, however, that substantial
interference effects, particularly those of the wave reflection type, may
be encountered under certain conditions, both in choked wind tunnels and
 in transonic wind tunnels, and that the reduction of these interference
 effects to acceptable limits may require the use of models of unusually
 small size .
```

3. Doc 1209 [IRRELEVANT]:
```
aerodynamic processes in the downwash-impingement problem .
  theoretical and experimental data relating to the downwash
impingement problem are examined in order to arrive at a
coherent understanding of the process of entrainment of ground
particles in the flow .  it is demonstrated that a key mechanism
in the process is the interaction of nonuniform flow in the ground
boundary layer with bluff ground particles .  this interaction
produces a lift force which, under typical conditions, equals or
exceeds the particle weight .
  in the interest of quantitative prediction of the conditions
necessary for particle entrainment, four subsidiary problem areas
in the impinging jet are examined .  these are the viscous decay,
the inviscid flow field, the ground boundary layer, and the forces
on a bluff body in nonuniform flow .  applicable theories are
used in conjunction with experimental data to assess the accuracy
and range of validity of the theories, and to define the stream
conditions which will cause particle entrainment .
  available data are applied to the establishment of criteria for
particle entrainment in the vicinity of the impinging-jet
stagnation point .  these criteria show that entrainment occurs in a
finite annular region on the ground plane, and that the particles
most readily entrained are those with a diameter equal to about
two-thirds the thickness of the ground boundary layer .  the
configuration size is shown to influence the process in that the
onset of entrainment is fixed by the jet diameter and velocity,
and the size of the ground particles .  the criteria established
provide a quantitative estimate of the conditions causing
entrainment and provide a basis for scaling experimental results to
a variety of full-scale situations .
```

4. Doc 228 [IRRELEVANT]
```
navier-stokes solutions at large distances from a finite body .
this paper is concerned with a theoretical investigation of the flow
field at large distances from an object moving through a viscous fluid .
the discussion will be restricted to the case of two-dimensional
stationary incompressible flow .  the object will be assumed to be of
finite size .  the domain of the fluid is infinite and it is assumed
that there are no other boundaries for the fluid except that of the
given object .  the reynolds number will be assumed to have a fixed
value., thus we shall not consider the limiting cases of the reynolds
number tending to zero or to infinity .
```

5. Doc 1245 [IRRELEVANT]
```
some aspects of nonequilibrium flows .
  in this paper are discussed some of the general features of
nonequilibrium flow .  in particular, vibrational relaxation is
discussed in detail .  this case is somewhat simpler than dissociation
and ionization but it illustrates some of the main new features of
nonequilibrium flow .  those aspects of two-dimensional and
axisymmetric flow behind shock waves are examined analytically
which yield significant information without requiring numerical
solution of the governing equations .
  the thermodynamics of a vibrational relaxing gas are
discussed .  the conditions for simulating flows are noted .  crocco's
theorem and the characteristic equations are derived .  then a
simple method of obtaining the initial gradients of the flow
variables behind a shock is shown .  these gradients are used in
discussing two particular flows .  an exact solution for flow over a
cusped body is obtained .  flow over a wedge near the tip and
far from the tip is considered .  it is found that far from the tip
a boundary-layer type phenomenon occurs .
```

#divider()

Query 22 : `did anyone else discover that the turbulent skin friction is not over
sensitive to the nature of the variation of the viscosity with
temperature .`

- BM25 MAP: 0.0010214504596527069
- Vetorial MAP: 0.0017094017094017094

1. Doc 125 [IRRELEVANT]
```
measurements of skin friction of the compressible turbulent
boundary layer on a cone with foreign gas injection .
  measurements of average skin friction of the turbulent
boundary layer have been made on a 15 total included angle cone with
foreign gas injection .  measurements of total skin-friction drag
were obtained at free-stream mach numbers of 0.3, 0.7, 3.5, and
x 10 with injection of helium, air, and freon-12
through the porous wall .  substantial reductions in skin
friction are realized with gas injection within the range of mach
numbers of this test .  the relative reduction in skin friction is
in accordance with theory--that is, the light gases are most
effective when compared on a mass flow basis .  there is a marked
effect of mach number on the reduction of average skin friction,.
this effect is not shown by the available theories .  limited
transition location measurements indicate that the boundary layer
does not fully trip with gas injection but that the transition point
approaches a forward limit with increasing injection .  the
variation of the skin-friction coefficient, for the lower injection rates
with natural transition, is dependent on the flow reynolds
number and type of injected gas,. and at the high injection rates the
skin friction is in fair agreement with the turbulent
boundary-layer results .
```

2. Doc 560 [IRRELEVANT]
```
a theoretical study of the effect of upstream
transpiration-cooling on the heat transfer and skin friction characteristics
of a compressible laminar boundary layer .
  an analysis is presented which predicts
the skin-friction and
heat-transfer characteristics of a compressible,
laminar boundary layer on a
solid flat plate preceded by a porous
section that is transpiration cooled .
the analysis is restricted to a prandtl
number of unity and linear
variation of viscosity with temperature .
  the local skin friction has been
found to have a low value in the
region of transpiration cooling and then
to increase until it approaches
the value for a completely nonporous surface
asymptotically .  the initial
increase in local skin friction is rapid
as half of the ultimate increase
occurs in a distance beyond the porous
region that is about 20 percent of
the length of the porous region for all rates
of injection .  when the
total coolant flow rate is kept constant
and the porous length is varied,
it is found that the average skin friction
on a partially porous plate is
slightly lower than that on a fully porous plate .
  the local heat transfer behaves in
a manner similar to that of the
local skin friction .  it is found, in
an example, that the temperature
at the end of a partially porous plate
could be maintained at about the
same temperature as a fully porous plate
by doubling the total rate of
coolant flow .
```

3. Doc 254 [IRRELEVANT]
```
boundary layers with suction and injection . a review
of published work on skin friction .
  available data on the effects of suction and injection on skin
friction are summarised and compared .
  it is shown that injection into a turbulent boundary layer can
produce a skin friction coefficient lower than the laminar value at the
same reynolds number on an impermeable plate .
```

4. Doc 413 [IRRELEVANT]
```
turbulent skin friction at high mach numbers and reynolds
numbers in air and helium . nasa r82, 1960 .
  results are given of local skin-friction measurements in turbulent
boundary layers over an equivalent air mach number range from 0.2 to 9.9
and an over-all reynolds number variation of 2x10 to 100x10 .  direct
force measurements were made by means of a floating element .  flows
were two-dimensional over a smooth flat surface with essentially zero
pressure gradient and with adiabatic conditions at the wall .  air and
helium were used as working fluids .  an equivalence parameter for
comparing boundary layers in different working fluids is derived and
the experimental verification of the parameter is demonstrated .
experimental results are compared with the results obtained by several
methods of calculating skin friction in the turbulent boundary layer .
```

5. Doc 307 [IRRELEVANT]
```
an approximate solution of hypersonic laminar boundary
layer equations and its application .
  approximate formulae of the displacement thickness and the skin
friction of the hypersonic laminar boundary layer are derived by use of
von karman's integral method, assuming the heat-insulated wall, the
prandtl number of unity and chapman and rubesin's formula for the
variation of viscosity with temperature .
the results obtained are
compared with some exact solutions .
because of the good agreement, it
seems that these formulae are very useful .
  these formulae, together with the tangent-wedge-approximation, are
applied to the viscous flow over
slender bodies with a sufficiently sharp
leading edge .  as an example, the
pressure distribution over a flat plate
is calculated numerically over the
entire region of the surface .
comparison with other author's theoretical
results as well as experimental
values is made .
```

== Variação de parâmetros do BM25

Foram estudadas variações dos parâmetros $k_1$ e $b$ do modelo probabilístico. As variações são concernentes a $k_1 in {0.5, 1.2, 2.0}$ e $b in {0, 0.75, 1}$

=== MAP agrupado por parâmetros

Primeiro, é útil verificar como cada parâmetro se saiu nos pipelines.

#grid(
	columns: (1fr, 1fr), // 2 equal-width columns
	gutter: 10pt, // Space between

	figure(image("../src/plots/metrics_probabilistic_k0.5_b0.0_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k0.5_b0.75_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k0.5_b1.0_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k1.2_b0.0_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k1.2_b0.75_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k1.2_b1.0_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k2.0_b0.0_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k2.0_b0.75_map.png", width: 100%)),
	figure(image("../src/plots/metrics_probabilistic_k2.0_b1.0_map.png", width: 100%)),
)

De modo geral, são feitas as seguintes observações (aplicáveis somente ao universo de $k$ e $b$ testados):

+ A remoção de stop words junto com o stemming se estabelece em definitivo como o melhor tipo de processamento para todas as variações do BM25.
+ A ausência da remoção de stop words e de stemming se estabelece em definitivo como o pior tipo de processamento para todas as variações do BM25.
+ Somente stemming foi o segundo melhor processamento em definitivo, exceto quando $b=0.0$. Nesse caso, a remoção de stop words se define como o segundo melhor processamento.
+ Para todo $k$, todos os scores são significativamente melhores para $b = 0.75$ em comparação a $b = 0.0$
+ Para todo $k$, todos os scores são desprezivelmente melhores e, por vezes, desprezivelmente piores para $b=1.0$ em comparação a $b = 0.75$, mas com $b=0.75$ sempre melhor que $b=0.0$ para o mesmo $k$.
+ Para todo $b$, todos os scores são melhores para $k=1.2$ em comparação a $k=0.5$
+ Para $b=0.75$ e $b=1.0$, todos os scores são levemente melhores para $k=2.0$ em comparação a $k=1.2$. Para $b=0.0$, isso varia entre leve melhora/piora.

As observações 1 e 2 já eram esperadas. A observação 3 mostra que a ausência do parâmetro $b$ (penalidade por tamanho do doucumento) representa um problema quando não há remoção de stop words, de modo que somente a remoção de stop words se destaca frente ao stemming. Pela observação 4, também pode-se afirmar que a presença do parâmetro $b$ sempre resulta em melhora significativa na precisão. Por último, a observação 5 revela uma saturação do parâmetro $b$, de modo que penalizar demais pelo tamanho do documento resulta em perda de precisão.

As observações 6 e 7 revelam, igualmente, uma saturação do parâmetro $k$.

=== Mapa de bolhas P\@10 x R\@10

Ao verificar o comportamento para Precision x Recall ao longo de k=1 até k=10, a ordem do score das variações se manteve estável, de modo que pode-se analisar somente k=10 e inferir o mesmo para k < 10.

#figure(image("../src/plots/precision_vs_recall_probabilistic_var_all_groups_bubble.png", width: 100%))

Em todos os casos, percebe-se, referente ao pipeline, uma ordem de eficiência: `WithStopRemovalWithStemming > NoStopRemovalWithStemming > WithStopRemovalNoStemming > NoStopRemovalNoStemming`. Essa observação foi feita em todas as análises anteriores.

No geral, percebe-se que as variações 5,6,8,9 sempre estão à frente das outras em todos os casos, alternando entre si. Assim, é válido considerá-los as melhores opções possíveis.

O melhor caso possível é `WithStopRemovalWithStemming` com $k=1.0$ e $b=0.75$.
