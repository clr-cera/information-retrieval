== Análise de erros

=== Top 1 não relevante para BM25

Query 5, BM25: `what chemical kinetic system is applicable to hypersonic aerodynamic problems`. Retornou `doc_id=103` em primeiro no ranking, sendo que é um documento não relevante.

Após o processamento: 

```
{'chemic': 1, 'kinet': 1, 'system': 1, 'applic': 1, 'hyperson': 1, 'aerodynam': 1, 'problem': 1}
```

Ranking:

`[('103', 0), ('1032', 0), ('401', 1), ('943', 0), ('552', 1), ('1296', 1), ('968', 0),
('625', 0), ('1374', 0), ('746', 0)]`

Doc `103` após o processamento:

```
{'theori': 1, 'mix': 2, 'chemic': 3, 'reaction': 1, 'oppos': 1, 'jet': 3, 'diffus': 1, 'flame': 3, '': 7, 'ideal': 1, 'flow': 3, 'system': 1, 'use': 1, 'potter': 2, 'butler': 2, 'analyz': 2, 'differenti': 2, 'equat': 2, 'solv': 1, 'exactli': 1, 'give': 1, 'locat': 1, 'burn': 1, 'rate': 3, 'solut': 1, 'kinet': 2, 'discuss': 1, 'relat': 1, 'deriv': 1, 'extinct': 2, 'constant': 1, 'laminar': 1, 'speed': 1, 'premix': 1, 'gase': 1, 'shown': 1, 'independ': 1, 'transport': 1, 'properti': 1, 'comparison': 1, 'made': 1, 'experiment': 1, 'data': 1, 'heimel': 1, 'argu': 1, 'experi': 1, 'must': 1, 'carri': 1, 'higher': 1, 'reynold': 1, 'number': 1, 'measur': 1, 'quantit': 1}
```

Analisando a interseção:

```
{'chemic': 3, 'system': 1, 'kinet': 2}
```

Doc `401` (primeiro relevante):

```
{'inviscid': 4, 'hyperson': 3, 'airflow': 3, 'coupl': 4, 'nonequilibrium': 4, 'process': 3, '': 16, 'analys': 1, 'made': 1, 'effect': 1, 'chemic': 2, 'rate': 2, 'extern': 1, 'high': 1, 'enthalpi': 1, 'level': 3, 'exact': 3, 'numer': 1, 'solut': 3, 'obtain': 1, 'invers': 1, 'method': 1, 'nearspher': 1, 'nose': 7, 'flight': 1, 'condit': 2, 'substanti': 1, 'prevail': 1, 'region': 2, 'typic': 1, 'consid': 3, 'includ': 3, 'radii': 1, 'order': 1, '1': 1, 'ft': 3, 'altitud': 2, '250000': 1, 'veloc': 4, '15000': 1, '23000': 1, 'per': 1, 'sec': 1, 'result': 2, 'illustr': 1, 'gener': 1, 'import': 3, 'among': 1, 'reaction': 4, 'dissociationrecombin': 1, 'bimolecularexchang': 1, 'ioniz': 1, 'show': 1, 'bimolecular': 1, 'exchang': 1, 'bluntnos': 2, 'flow': 5, 'kinet': 2, 'n': 1, 'case': 1, 'plane': 2, 'shock': 4, 'wave': 1, 'differ': 1, 'howev': 1, 'gasdynam': 1, 'expans': 2, 'curv': 1, 'layer': 2, 'former': 1, 'reduc': 1, 'postshock': 1, 'consequ': 1, 'regim': 2, 'studi': 1, 'oxygen': 1, 'nitrogenatom': 1, 'concentr': 1, 'tend': 1, 'freez': 1, 'infiniter': 1, 'equilibrium': 2, 'reduct': 1, 'dissoci': 2, 'larg': 1, 'particularli': 1, 'nitrogen': 1, 'higher': 1, 'domin': 1, 'twobodi': 1, 'collis': 1, 'phenomena': 2, 'thu': 1, 'amen': 1, 'binari': 2, 'scale': 4, 'given': 2, 'demonstr': 1, 'rang': 1, 'correl': 1, 'constant': 1, 'product': 1, 'ambient': 1, 'densiti': 1, 'radiu': 1, 'similitud': 1, 'also': 1, 'viscou': 1, 'radiat': 1, 'provid': 1, 'use': 1, 'flexibl': 1, 'test': 1, 'applic': 1, 'afterbodi': 1, 'inviscidflow': 1, 'problem': 1, 'briefli': 1, 'discuss': 1, 'light': 1}
```

Intersecção:

```
{'chemic': 2, 'kinet': 2, 'n': 1,'problem': 1}
```

É fácil analisar que o documento irrelevante foi colocado no top 1 por dois motivos: possui maior frequência de palavras e menor tamanho de documento. Além disso, o documento relevante tem muitos termos muito específicos que poderiam ter sido utilizados na query. O modelo probabilístico se mostra ineficiente na falta de termos-chave. Mesmo que existam muitos termos similares a "aerodynam", como "flight", eles são ignorados.

=== Top 1 não relevante para modelo vetorial

Query 3, modelo vetorial: `what problems of heat conduction in composite slabs have been solved sonfar`. Retornou `doc_id=485` em primeiro no ranking, sendo que é um documento não relevante.

Após o processamento:

```
{'problem': 1, 'heat': 1, 'conduct': 1, 'composit': 1, 'slab': 1, 'solv': 1, 'sonfar': 1}
```

Ranking:

```
[('485', 0), ('399', 1), ('5', 1), ('144', 1), ('579', 0), ('91', 1), ('625', 0),
('90', 1), ('1072', 0), ('344', 0)]
```

Doc `485` após o processamento:

```
{'linear': 2, 'heat': 2, 'flow': 1, 'composit': 2, 'slab': 2, '': 2, 'temperatur': 2, 'determin': 1, 'function': 2, 'posit': 1, 'time': 1, 'case': 1, 'conduct': 1, 'ture': 1, 'throughout': 1, 'two': 1, 'extern': 1, 'surfac': 1, 'consid': 1, 'prescrib': 1}
```

Intersecção:

```
{'heat': 2, 'composit': 2, 'slab': 2, 'conduct': 1}
```

Doc `399` (primeiro relevante) após o processamento:

```
{'conduct': 1, 'heat': 3, 'composit': 1, 'slab': 1, '': 2, 'method': 1, 'calcul': 1, 'total': 1, 'quantiti': 1, 'pass': 1, 'unit': 1, 'area': 1, 'zero': 2, 'time': 2, 'develop': 1, 'allow': 1, 'made': 1, 'surfac': 1, 'resist': 3, 'regard': 1, 'contact': 1, 'addit': 1, 'layer': 1, 'appropri': 1, 'thermal': 1, 'capac': 1}
```

Intersecção:

```
{'conduct': 1, 'heat': 3, 'composit': 1, 'slab': 1}
```

O doc `485` ganha por ter uma frequência maior frente à mesma intersecção de termos entre documento e query.

=== Documento relevante omitido no modelo vetorial

Query 1 modificada: `what similarity laws must be obeyed when constructing aeroelastic models of aircraft`. Ranking: `doc_id=13` relevante na posição 50.

Após o processamento:

```
{'similar': 1, 'law': 1, 'must': 1, 'obey': 1, 'construct': 1, 'aeroelast': 1, 'model': 1, 'aircraft': 1}
```

Doc `13` após o processamento:

```
{'similar': 3, 'law': 2, 'stress': 3, 'heat': 5, 'wing': 3, '': 6, 'shown': 1, 'differenti': 1, 'equat': 1, 'plate': 5, 'larg': 1, 'temperatur': 2, 'gradient': 1, 'constant': 1, 'made': 1, 'proper': 1, 'modif': 1, 'thick': 1, 'load': 3, 'isotherm': 1, 'fact': 1, 'lead': 1, 'result': 1, 'calcul': 1, 'measur': 1, 'strain': 1, 'unheat': 2, 'seri': 1, 'relat': 1, 'call': 1, 'applic': 1, 'analog': 3, 'theori': 1, 'solid': 1, 'aerodynam': 1, 'discuss': 2, 'detail': 1, 'howev': 1, 'complic': 1, 'involv': 1, 'novel': 1, 'concept': 1, 'feedback': 1, 'bodi': 1, 'forc': 1, 'problem': 1, 'boxw': 1, 'structur': 1, 'solv': 1, 'method': 1, 'briefli': 1}
```

Intersecção com query:

```
{'similar': 3, 'law': 2}
```

O modelo vetorial falha em resgatar o documento pois há poucos termos na intersecção (apenas 2, 25% do total). O fato de haver alta frequência não possui muito impacto por conta do IDF.
