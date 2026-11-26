== Busca híbrida (RRF)

Os rankings lexical e semântico são combinados por *Reciprocal Rank Fusion* (`reciprocal_rank_fusion`, em `src/ir/neural.py`):

$ "RRF"(d) = sum_(s in {"lexical", "semântico"}) 1 / (k + "rank"_s (d)) $

em que $"rank"_s (d)$ é a posição de $d$ no ranking do sistema $s$, começando em 1. São fundidos os 100 primeiros documentos de cada ranking; um documento ausente dos 100 primeiros de um sistema não recebe contribuição dele, e os empates são resolvidos pelo id do documento.

No dev, o NDCG\@10 foi 0,3299 com $k = 10$, 0,3273 com $k = 60$ e 0,3273 com $k = 100$, contra 0,2906 do lexical e 0,3024 do semântico. Foi escolhido $k = 10$, mantido no test. As diferenças são pequenas porque, com $k$ grande, $1\/(k + "rank")$ varia pouco entre as posições. Ainda assim, as 3 configurações superaram o desempenho do lexical e semântico.
