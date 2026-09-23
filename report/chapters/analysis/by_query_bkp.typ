== Análise por consulta

Serão selecionadas 2 consultas para cada modelo onde o resultado foi claramente discrepante (de modo positivo). O pipeline utilizado foi o completo `WithStopRemovalWithStemming`. Os parâmetros utilizados para o modelo probabilístico foram $k=1.2$ e $b=1.0$.

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
```
second approximation to laminar compressible boundary
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

- BM25 MAP: 0.41
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

