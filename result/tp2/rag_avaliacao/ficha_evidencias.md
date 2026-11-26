# Ficha de evidências por resposta

Apoio à avaliação humana do RAG. Para cada item das planilhas (R01 a R20, na mesma ordem), a ficha lista as afirmações principais da resposta e diz o que os 5 documentos da consulta (`documentos_por_consulta.md`) dizem sobre cada uma. Ela **não traz notas nem indica a condição** (A ou B): as notas são decididas por cada avaliador.

Elaborada com apoio do Claude Code (IA) em 26/11/2026, a partir das respostas e dos documentos. Confiram cada ponto nos documentos antes de usar. Os dois avaliadores usarem a mesma ficha tende a aproximar as notas; isso deve ser mencionado ao reportar a concordância.

**Legenda** (sempre em relação aos 5 documentos da consulta):

- **Apoiada [MED-x]:** o documento diz isso.
- **Parcial [MED-x]:** o documento diz algo próximo, mas a resposta exagera, generaliza ou mistura detalhes.
- **Sem apoio:** nenhum dos 5 documentos trata disso (pode estar certo ou errado; não dá para verificar com o contexto).
- **Contradita [MED-x]:** o documento diz o contrário.

---

## R01 — PLAIN-3342: Is Coconut Milk Good For You?

| Afirmação | Evidência |
|---|---|
| Os documentos não trazem informação específica sobre os efeitos do leite de coco | Apoiada: nenhum dos 5 estuda leite de coco isoladamente; o MED-5014 só o inclui no consumo de coco em geral |
| Consumo de coco (polpa ou leite) não diferiu entre casos de doença coronariana e controles nos Minangkabau | Apoiada [MED-5014] |
| Gordura saturada do coco não foi preditora de doença coronariana nesse grupo | Apoiada [MED-5014] |
| Óleo de coco com possíveis benefícios lipídicos | Apoiada [MED-4000: HDL maior; MED-4002: HDL maior e menor razão LDL:HDL] |
| Flocos de coco com benefício lipídico | Apoiada [MED-5012: redução de colesterol total e LDL] |
| Conclusão: não é possível determinar se o leite de coco faz bem | Apoiada (decorre da ausência de estudos sobre leite de coco) |

- **Citações:** MED-5014, MED-4000, MED-4002, MED-5012, todas entre os 5 documentos e usadas para o que dizem.
- **Não usado:** MED-5015 (água de coco intravenosa), que não é relevante para a pergunta.

## R02 — PLAIN-153: How Should I Take Probiotics?

| Afirmação | Evidência |
|---|---|
| Tomar com uma refeição que contenha alguma gordura, ou logo antes | Apoiada [MED-3679] |
| ProtecFlor®: sobrevivência melhor com a refeição ou 30 min antes; 30 min depois, poucos sobrevivem | Apoiada [MED-3679] |
| Sobrevivência melhor em leite 1% e mingau de aveia com leite do que em suco de maçã ou água | Apoiada [MED-3679] |
| Proteína da refeição provavelmente menos importante que a gordura | Apoiada [MED-3679] |
| Vale para o produto testado (lactobacilos, *Bifidobacterium*, *Saccharomyces*) | Apoiada [MED-3679] |

- **Citações:** só MED-3679, que está entre os 5 documentos.
- **Ressalvas:** o estudo usa um *modelo in vitro* do trato digestivo, o que a resposta não menciona; o documento restringe a conclusão a produtos *sem revestimento entérico* (a resposta cita isso).
- **Não usado:** MED-3693 (só 4 de 13 produtos comerciais conferiam com o rótulo), útil para "como tomar/escolher".

## R03 — PLAIN-2430: Preventing Brain Loss with B Vitamins?

| Afirmação | Evidência |
|---|---|
| Vitaminas B (B6, folato, B12) reduzem a homocisteína, ligada ao declínio cognitivo | Apoiada [MED-994, MED-980, MED-5128] |
| Mantêm a função nervosa; deficiência de B12 causa dano neurológico | Parcial: o MED-5128 liga B12 baixa a declínio cognitivo mais rápido; dano neurológico não é tratado |
| Ajudam a reduzir o risco de demência quando a homocisteína está alta | Parcial: MED-994 e MED-980 mostram menos *atrofia cerebral* nesse grupo; efeito sobre demência ainda não foi demonstrado (MED-994, MED-986) |
| Não previnem sozinhas o declínio relacionado à idade | Compatível [MED-986: sem melhora da função cognitiva em 19 ensaios] |
| Priorizar alimentos; excesso de B6 causa dano nervoso; exercício e controle da pressão | Sem apoio |

- **Citações:** nenhuma.
- **Não mencionado:** o resultado central dos documentos para "brain loss": a redução da atrofia cerebral com vitaminas B em idosos com comprometimento cognitivo leve e homocisteína alta (MED-994, MED-980).

## R04 — PLAIN-153: How Should I Take Probiotics?

| Afirmação | Evidência |
|---|---|
| Tomar com as refeições, porque o alimento protege as bactérias do ácido do estômago | Parcial [MED-3679: melhor com a refeição ou 30 min antes, e com refeição que contenha gordura] |
| Guardar refrigerado; não aquecer nem congelar | Sem apoio |
| Tomar diariamente no mesmo horário; 1–2 cápsulas por dia | Sem apoio |
| Conferir no rótulo as culturas vivas e a cepa | Sem apoio; o MED-3693 indica que os rótulos frequentemente não correspondem ao conteúdo (só 31% conferiam) |
| Consultar um médico, especialmente com imunidade baixa | Sem apoio |

- **Citações:** nenhuma.

## R05 — PLAIN-2750: Preventing the Common Cold with Probiotics?

| Afirmação | Evidência |
|---|---|
| *L. plantarum* HEAL 9 + *L. paracasei* 8700:2 reduziram o risco de resfriado de 67% para 55% (p < 0,05) em 12 semanas | Apoiada [MED-3683] |
| Dias com sintomas de 8,6 para 6,2 | Apoiada [MED-3683] |
| Redução significativa da gravidade | Parcial [MED-3683: escore total caiu de 44,4 para 33,6, mas só a redução dos sintomas faríngeos foi significativa] |
| Melhora da resposta imune celular | Parcial [MED-3683: a proliferação de linfócitos B foi "contrabalançada"; a resposta interpreta] |
| Em crianças de 3–5 anos, menos febre, tosse, coriza e uso de antibióticos | Apoiada [MED-4762]; a coriza só foi significativa com a combinação de cepas |
| Cepas específicas reduzem incidência e gravidade em populações diferentes | Apoiada [MED-3683, MED-4762] |

- **Citações:** MED-3683 e MED-4762, ambos entre os 5 documentos.
- **Não usado:** MED-3680 (revisão Cochrane: probióticos melhores que placebo para prevenir infecções respiratórias agudas), que reforça a resposta.

## R06 — PLAIN-2470: Is Milk Good for Our Bones?

| Afirmação | Evidência |
|---|---|
| Leite tem cálcio, fósforo e proteína e é fortificado com vitamina D nos EUA, o que pode melhorar a saúde óssea | Apoiada [MED-1337] |
| Mulheres: sem associação entre leite e fratura de quadril (RR 0,99; IC 0,96–1,02) | Apoiada [MED-1337] |
| Homens: levemente protetor, sem significância (RR 0,91; IC 0,81–1,01) | Apoiada [MED-1337, que conclui que faltam dados em homens] |
| Leite na adolescência: risco maior de fratura em homens (RR 1,09), não em mulheres | Apoiada [MED-1340]; a resposta omite que a associação diminui ao ajustar pela altura (RR 1,06) |
| A evidência não mostra que o leite reduz o risco de fratura de quadril | Apoiada [MED-1337, MED-1340] |

- **Citações:** MED-1337 e MED-1340, entre os 5 documentos.
- **Não usado:** MED-1338 (coortes suecas: consumo alto de leite associado a *mais* fraturas em mulheres e maior mortalidade), relevante para a pergunta.
- **Escopo:** a resposta trata só de fratura de quadril.

## R07 — PLAIN-2430: Preventing Brain Loss with B Vitamins?

| Afirmação | Evidência |
|---|---|
| Doses: ácido fólico 0,8 mg, B6 20 mg, B12 0,5 mg | Apoiada [MED-994] |
| Atrofia reduzida em até sete vezes nas regiões de substância cinzenta ligadas ao Alzheimer, em quem tinha homocisteína > 11 µmol/L | Parcial [MED-994]: as duas informações estão no documento, mas a resposta as junta numa frase só |
| Ensaio randomizado: atrofia 53% menor com homocisteína > 13 µmol/L | Apoiada [MED-980] |
| Vitaminas B não melhoraram a função cognitiva em 19 ensaios | Apoiada [MED-986] |
| O benefício se restringe a quem tem homocisteína alta | Apoiada [MED-994, MED-980] |

- **Citações:** MED-994, MED-980, MED-986, todas entre os 5 documentos.
- **Ressalva:** os participantes são idosos com comprometimento cognitivo leve; a resposta fala só em "populações específicas".
- **Não usado:** MED-5128 (B12 baixa associada a declínio cognitivo mais rápido).

## R08 — PLAIN-3342: Is Coconut Milk Good For You?

| Afirmação | Evidência |
|---|---|
| Rico em triglicerídeos de cadeia média, que ajudam o metabolismo sem elevar a glicemia | Sem apoio |
| Sem lactose, pouco sódio, com vitamina C e ácido láurico | Sem apoio |
| Rico em gordura saturada, que pode elevar o LDL e o risco cardíaco | Em tensão com os documentos: no MED-5014, a gordura saturada (inclusive do coco) não foi preditora de doença coronariana; MED-4000 e MED-4002 associam óleo de coco a HDL maior e não a dislipidemia |
| 100–150 kcal por xícara; sem proteína e fibra | Sem apoio |
| Recomenda 1–2 xícaras por dia, sem açúcar | Sem apoio |

- **Citações:** nenhuma.

## R09 — PLAIN-2850: More Antibiotics In White Meat or Dark Meat?

| Afirmação | Evidência |
|---|---|
| Antibióticos não estão naturalmente na carne; vêm de resíduos de animais tratados | Sem apoio |
| A cor da carne não determina o nível de antibióticos; resíduos semelhantes em cortes do mesmo animal | Sem apoio nos 5 documentos. Fora do contexto, o MED-4166 (relevante nos qrels, 19º após o reranking) mostra concentração maior no peito do que na coxa de frangos, o contrário da resposta |
| Regulamentações limitam resíduos a níveis seguros | Sem apoio |
| Carne escura tem um pouco mais de gordura | Sem apoio |

- **Citações:** nenhuma.
- **Lembrete:** pelo enunciado, a fidelidade é julgada contra os 5 documentos enviados; a informação do MED-4166 serve para a discussão.

## R10 — PLAIN-2470: Is Milk Good for Our Bones?

| Afirmação | Evidência |
|---|---|
| Sim, o leite em geral faz bem aos ossos, pelo cálcio | Contradita/em tensão: MED-1337 (sem associação com fratura de quadril em mulheres), MED-1340 (leite na adolescência não reduz fraturas; risco maior em homens), MED-1338 (mais fraturas em mulheres com consumo alto). Só a composição nutricional é apoiada [MED-1337] |
| Fornece vitamina D quando fortificado | Apoiada [MED-1337] |
| Ajuda a densidade óssea e a atingir a necessidade de cálcio | Sem apoio |
| Alternativas para intolerância à lactose; vitamina D é igualmente importante | Sem apoio |

- **Citações:** nenhuma.

## R11 — PLAIN-238: How Chemically Contaminated Are We?

| Afirmação | Evidência |
|---|---|
| PFOA em 17 de 31 amostras; pesticidas organoclorados (maiores níveis de metabólitos do DDT) e PCBs em alimentos dos EUA | Apoiada [MED-2391] |
| Maior ingestão: DDT e metabólitos, endossulfanos, aldrina, PCBs e PFOA | Apoiada [MED-2391] |
| A dieta contribui para a exposição a ftalatos: aves (DEHP), tomate e batata (monoetil ftalato) | Apoiada [MED-4653] |
| Corantes caramelo podem ter 2- e 4-metilimidazol, carcinogênicos, acima dos limites federais | Apoiada [MED-2994] |
| Apesar das proibições, esses químicos continuam nos alimentos | Parcial [MED-2391]: a frase do documento é sobre os poluentes orgânicos persistentes; a resposta generaliza para todos |

- **Citações:** MED-2391, MED-4653, MED-2994, entre os 5 documentos.
- **Escopo:** os dados são dos EUA; a pergunta é geral.
- **Não usado:** MED-4739 (toxicantes na gestação, mercúrio em frutos do mar) e MED-2493 (exposição no desenvolvimento e sistema imune).

## R12 — PLAIN-270: Is Caffeinated Tea Really Dehydrating?

| Afirmação | Evidência |
|---|---|
| Chá com cafeína não desidrata de forma significativa | Apoiada [MED-4331] |
| A cafeína é um diurético leve; a água do chá e a L-teanina compensam | Sem apoio |
| Estudos mostram que 1–2 xícaras por dia não causam desidratação | Parcial [MED-4331 testou 4 e 6 xícaras de 240 ml (168 e 252 mg de cafeína)] |
| Hidrata como a água | Apoiada [MED-4331] |
| 40–70 mg de cafeína por xícara de chá contra 95 mg no café | Sem apoio |
| Chás com muita cafeína (matcha) podem ter efeito leve | Sem apoio |

- **Citações:** nenhuma.

## R13 — PLAIN-68: What is Actually in Chicken Nuggets?

| Afirmação | Evidência |
|---|---|
| Estudo de "autópsia" de nuggets de duas redes nacionais de fast food | Apoiada [MED-2991] |
| "Striated muscle (chicken meat) was not the predominate component in either nugget" | Apoiada: citação literal [MED-2991] |
| "Fat was present in equal or greater quantities along with epithelium, bone, nerve, and connective tissue" | Apoiada: citação literal [MED-2991] |
| "Chicken nuggets are mostly fat, and their name is a misnomer" | Apoiada: citação literal da conclusão [MED-2991] |

- **Citações:** só MED-2991, entre os 5 documentos.
- **Ressalva:** o estudo analisou poucos nuggets de duas redes; a resposta generaliza como o próprio documento.
- **Não usado:** MED-2492 (arsênio e roxarsona em carne de frango), que também fala do que há no frango; os outros três documentos não respondem à pergunta.

## R14 — PLAIN-270: Is Caffeinated Tea Really Dehydrating?

| Afirmação | Evidência |
|---|---|
| "Black tea is not significantly different from water in the maintenance of normal hydration in human subjects" | Apoiada: é o título do MED-4331 |
| Ensaio randomizado com 21 homens saudáveis | Apoiada [MED-4331] |
| Sem diferença entre chá e água em nenhuma medida de sangue ou urina (lista de medidas) | Apoiada [MED-4331] |
| Testou 168 e 252 mg de cafeína, com 20 ml de leite semidesnatado | Apoiada [MED-4331] |
| Não desidrata nas quantidades estudadas | Apoiada [MED-4331] |

- **Citações:** só MED-4331, entre os 5 documentos.
- **Ressalva:** só homens, em repouso, 12 h de intervenção; a resposta menciona "healthy males" e "amounts studied".
- **Não usado:** os outros 4 documentos tratam de refluxo e função endotelial e não respondem à pergunta.

## R15 — PLAIN-2450: Are Organic Foods Safer?

| Afirmação | Evidência |
|---|---|
| Orgânicos são mais seguros quanto a pesticidas | Apoiada [MED-1140, MED-1178, MED-1179] |
| Evitam pesticidas sintéticos e transgênicos | Sem apoio (transgênicos não são tratados) |
| Resíduos até 30–40% menores | Parcial [MED-1178: o *risco de resíduo detectável* é 30% menor (IC 23–37%); não é a quantidade de resíduo] |
| O ganho de saúde é pequeno; os resíduos dos convencionais têm baixo risco | Apoiada [MED-1140: níveis bem abaixo dos limites; MED-1178: diferença pequena no risco de exceder limites] |
| Controle natural de pragas; mais antioxidantes não significa mais segurança | Sem apoio |
| A escolha reflete mais valores pessoais que segurança | Compatível [MED-1140: "outros fatores, e não a segurança, parecem favorecer os orgânicos"] |

- **Citações:** nenhuma.
- **Não mencionado:** bactérias resistentes a antibióticos menos frequentes em frango e porco orgânicos (MED-1178); "orgânico não é automaticamente seguro" para outros riscos (MED-1140).

## R16 — PLAIN-238: How Chemically Contaminated Are We?

| Afirmação | Evidência |
|---|---|
| Exposição a muitos químicos sintéticos por alimentos, água, ar e produtos | Parcial [MED-2391, MED-4653: alimentos; MED-4739, MED-2493: ambiente] |
| "Segundo a OMS e estudos ambientais globais" | Sem apoio: fonte externa, que não está no contexto |
| Pesticidas, metais pesados, PFAS, microplásticos | Parcial: pesticidas e PFOA [MED-2391], mercúrio [MED-4739]; microplásticos sem apoio |
| PFAS em águas subterrâneas e no sangue no mundo todo; microplásticos nos oceanos | Sem apoio |
| Efeitos: disrupção endócrina, câncer, problemas de desenvolvimento | Parcial [MED-4739, MED-2493: desenvolvimento; MED-2994: câncer em animais] |
| A maioria das populações fica abaixo dos limites críticos, por regulação e destoxificação natural | Sem apoio; em tensão com MED-2391 (poluentes presentes apesar das proibições) e MED-2994 (podem exceder limites federais) |

- **Citações:** nenhuma.

## R17 — PLAIN-2850: More Antibiotics In White Meat or Dark Meat?

| Afirmação | Evidência |
|---|---|
| Os documentos não informam sobre antibióticos em carne branca versus escura | Apoiada: nenhum dos 5 mede resíduos de antibióticos |
| Isolados de *E. coli* de aves têm mais resistência que os de carne bovina | Apoiada [MED-3891] |
| Aves = carne branca, carne bovina = carne escura | Imprecisa: na pergunta, "dark meat" é a carne escura das aves (coxa), não a carne bovina |
| O MED-3891 trata de resistência bacteriana, não de resíduos | Apoiada [MED-3891] |
| Não há evidência suficiente para responder | Apoiada (decorre do contexto) |

- **Citações:** só MED-3891, entre os 5 documentos.
- **Lembrete:** a resposta para a pergunta está no MED-4166, que não chegou ao contexto (ver `rag_stage_trace.md`).

## R18 — PLAIN-2750: Preventing the Common Cold with Probiotics?

| Afirmação | Evidência |
|---|---|
| A evidência não apoia probióticos para *prevenir* resfriados; a maioria dos estudos não mostra redução da incidência | Contradita: MED-3683 (incidência de 67% para 55%, p < 0,05), MED-3680 (Cochrane: menos participantes com episódios, OR 0,58) e MED-4762 (menos febre, tosse e coriza em crianças) |
| Podem encurtar um pouco a duração, de forma inconsistente e sem relevância clínica | Em tensão: MED-3683 (8,6 para 6,2 dias) e MED-4762 (duração 32–48% menor) mostram redução; MED-3680 não encontrou diferença na duração |
| Lavar as mãos, dormir bem, evitar doentes | Sem apoio |
| Probióticos não são um método confiável de prevenção | Contradita [MED-3683, MED-3680, MED-4762] |

- **Citações:** nenhuma.

## R19 — PLAIN-68: What is Actually in Chicken Nuggets?

| Afirmação | Evidência |
|---|---|
| Principalmente pedaços processados de frango, farinha, empanado, óleo, sal | Contradita em parte [MED-2991: carne de frango (músculo estriado) não é o componente predominante; gordura em quantidade igual ou maior, com epitélio, osso, nervo e tecido conjuntivo] |
| Aditivos: benzoato de sódio, amarelo 5, fosfato de sódio, xarope de milho | Sem apoio |
| O frango é moído; o processamento reduz a proteína | Parcial [MED-2991 indica pouco músculo, mas não fala de moagem] |
| Muito sódio (400–600 mg por porção), gordura saturada, calorias vazias | Gordura: compatível [MED-2991]; sódio e números: sem apoio |

- **Citações:** nenhuma.

## R20 — PLAIN-2450: Are Organic Foods Safer?

| Afirmação | Evidência |
|---|---|
| Risco 30% menor de contaminação detectável por pesticidas | Apoiada [MED-1178] |
| Níveis de contaminação dos dois tipos bem abaixo dos limites aceitáveis | Apoiada [MED-1140] |
| Menor risco de bactérias resistentes a antibióticos em aves orgânicas | Apoiada [MED-1178], que também inclui carne de porco |
| "Organic" does not automatically equal "safe" | Apoiada: citação literal [MED-1140] |
| Dietas orgânicas expõem a menos pesticidas associados a doenças | Apoiada: citação literal [MED-1179] |
| A evidência não mostra vantagens de segurança além desse aspecto | Parcial [MED-1179, MED-1140]; a própria resposta citou antes outra vantagem (bactérias resistentes) |
| Mais de 90% dos entrevistados percebem menor risco de resíduos de pesticidas | Apoiada [MED-1144] |

- **Citações:** MED-1178, MED-1140, MED-1179, MED-1144, todas entre os 5 documentos e usadas para o que dizem.
- **Não usado:** MED-1173 (motivações de compradores suecos), pouco relevante para segurança.
