== Modificação de queries

- Query 1: what similarity laws must be obeyed when constructing aeroelastic models of heated high speed aircraft .
- Query 1 (*alternativa*): what similarity laws must be obeyed when construction aereoelastic models of aricraft .

- Query 2: what are the structural and aeroelastic problems associated with flight of high speed aircraft .
- Query 2 (*alternativa*): what are the aeroelastic problems associated with flight of high speed aircraft

- Query 3: what problems of heat conduction in composite slabs have been solved so\nfar .
- Query 3 (*alternativa*): what problems of transient heat conduction in composite slabs have been solved so far .

- Query 5:what chemical kinetic system is applicable to hypersonic aerodynamic problems .
- Query 5 (*alternativa*): what chemical kinetic mechanism is applicable to hypersonic aerodynamic problems .

- Query 12: how can the aerodynamic performance of channel flow ground effect machines be calculated .
- Query 12 (*alternativa*): how can the aerodynamic performance of ground effect machines be calculated .

O top 101 será mostrado como ele é dado pelo modelo: um array ordenado de `doc_ids`, com um bit `0` ou `1` para indicar se o documento é relevante.

=== BM25

Query 1:

`[('51', 1), ('486', 0), ('878', 0), ('12', 1), ('573', 0), ('944', 0), ('746', 0), ('879', 1), ('141', 0), ('747', 0)]`

Query 1_mod: 

`[('51', 1), ('486', 0), ('573', 0), ('878', 0), ('12', 1), ('944', 0), ('875', 1), ('359', 0), ('184', 1), ('219', 0)]`

Remover "heated high speed aircraft" não alterou o top 1 relevante, tirou uma posição do top 4 e trouxe 2 documentos relevantes diferentes, mas perdeu 1 que havia recuperado. Em média, o modelo BM25 lida bem com a falta de palavras.

Query 2: 

`[('12', 1), ('746', 1), ('51', 1), ('1089', 0), ('1169', 0), ('100', 0), ('172', 0), ('810', 0), ('1380', 0), ('700', 0)]`

Query 2_mod: 

`[('12', 1), ('746', 1), ('1089', 0), ('1169', 0), ('172', 0), ('810', 0), ('700', 0), ('51', 1), ('14', 1), ('1158', 0)]`

Remover "structural" não alterou o top 2 e fez um documento relevante no top3 perder posições, mas trouxe mais um documento relevante. A consulta piorou.

Query 3:

`[('485', 0), ('5', 1), ('399', 1), ('144', 1), ('181', 1), ('91', 1), ('90', 1), ('579', 0), ('6', 1), ('542', 0)]`

Query 3_mod: 

`[('5', 1), ('485', 0), ('399', 1), ('144', 1), ('91', 1), ('6', 1), ('181', 1), ('90', 1), ('579', 0), ('980', 0)]`

Adicionar "transient" manteve todos os documentos relevantes anteriormente resgatados no top 10, colocou um documento relevante na primeira posição no lugar de um não relevante, e o resto apenas permutou. Adicionar "transient" deixou a consulta mais sólida.

Query 5: 

`[('103', 0), ('1032', 0), ('401', 1), ('943', 0), ('552', 1), ('1296', 1), ('968', 0), ('625', 0), ('1374', 0), ('746', 0)]`

Query 5_mod: 

`[('1296', 1), ('401', 1), ('103', 0), ('625', 0), ('552', 1), ('1374', 0), ('837', 0), ('746', 0), ('488', 0), ('707', 0)]`

Trocar "system" por "mechanism" alterou drasticamente o ranking, colocando dois dos três documentos relevantes no top2 e mantendo um intacto. Muito provavelmente "mechanism" é mais discriminativo.

Query 12: 

`[('650', 1), ('624', 0), ('966', 0), ('1232', 0), ('1221', 0), ('941', 0), ('939', 0), ('1164', 0), ('652', 1), ('270', 0)]`

Query 12_mod: 

`[('650', 1), ('624', 0), ('1232', 0), ('1164', 0), ('543', 0), ('704', 0), ('652', 1), ('1223', 0), ('1094', 0), ('506', 0)]`

Remover "channel flow" manteve o top 1 relevante e melhorou duas posições do próximo documento relevante. O modelo BM25 lida bem com a falta de palavras específicas.

=== Modelo vetorial

Query 1:

`[('573',0), ('329', 0), ('944', 0), ('486', 0), ('12', 1), ('1194', 0), ('78', 0), ('51', 1), ('14', 1), ('414', 0)]`

Query 1_mod: 

`[('573', 0), ('329', 0), ('944', 0), ('1194', 0), ('486', 0), ('414', 0), ('78', 0), ('14', 1), ('51', 1), ('202', 0)]`

Remover "heated high speed aircraft" piorou a posição dos relevantes, perdendo um em comparação ao original. Remover muitas palavras específicas piora drasticamente a qualidade do modelo vetorial.

Query 2: 

`[('12', 1), ('78', 0), ('14', 1), ('172', 0), ('746', 1), ('202', 1), ('1089', 0), ('1380', 0), ('486', 0), ('914', 0)]`

Query 2_mod: 

`[('12', 1), ('14', 1), ('172', 0), ('78', 0), ('746', 1), ('1089', 0), ('914', 0), ('141', 0), ('202', 1), ('364', 0)]`

Remover "structural" melhorou em 1 posição o top3 relevante, desceu 3 posições do top6 relevante e manteve os outros intactos. Remover palavras piora a consulta.

Query 3: 

`[('485', 0), ('399', 1), ('5', 1), ('144', 1), ('579', 0), ('91', 1), ('625', 0), ('90', 1), ('1072', 0), ('344', 0)]`

Query 3_mod: 

`[('5', 1), ('91', 1), ('485',  0), ('399', 1), ('144', 1), ('579', 0), ('625', 0), ('90', 1), ('6', 1), ('1072', 0)]`

Adicionar "transient" melhorou a posição, em geral, dos relevantes e trouxe mais um. Adicionar palavras específicas melhorou a consulta.

Query 5: 

`[('401', 1), ('625', 0), ('103', 0), ('943', 0), ('328', 0), ('552',1), ('1296', 1), ('1147', 0), ('1072', 0), ('77', 0)]`

Query 5_mod: 

`[('625',  0), ('1296',  1), ('1072', 0), ('401', 1), ('328', 0), ('552', 1), ('103', 0), ('357', 0), ('943', 0), ('976', 0)]`

Trocar "system" por "kinect" praticamente inverteu o top1 e top7, mantendo o top6 intacto. Provavelmente o que veio à frente possuía "kinect" (ou em maior quantidade).

Query 12: 

`[('624', 0), ('966', 0), ('1232', 0), ('650', 1), ('325', 0), ('792', 0), ('506', 0), ('939', 0), ('704', 0), ('810', 0)]`

Query 12_mod: 

`[('624', 0), ('1232', 0), ('650', 1), ('325', 0), ('792', 0), ('506', 0), ('810', 0), ('1168', 0), ('704', 0), ('717', 0)]`

Remover "channel flow" melhorou em 1 posição o único documento relevante. Provavelmente o que estava à frente tinha alguma das duas palavras.
