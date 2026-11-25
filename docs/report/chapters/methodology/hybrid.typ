== Busca híbrida (RRF)

Os rankings lexical e semântico são combinados por *Reciprocal Rank Fusion* (função `reciprocal_rank_fusion`, em `src/ir/neural.py`). O score de um documento $d$ é

$ "RRF"(d) = sum_(s in {"lexical", "semântico"}) 1 / (k + "rank"_s (d)) $

em que $"rank"_s (d)$ é a posição de $d$ no ranking do sistema $s$, começando em 1. São fundidos os 100 primeiros documentos de cada sistema; um documento ausente dos 100 primeiros de um sistema não recebe contribuição desse sistema. O ranking híbrido é ordenado pelo score RRF, com empates resolvidos pelo identificador do documento.

O RRF usa apenas as *posições*, e não os scores. Isso evita comparar valores de escalas diferentes: o BM25 não tem limite superior (os scores do topo variam entre cerca de 2 e 17 nas consultas analisadas), enquanto o cosseno fica entre −1 e 1. A constante $k$ controla o peso das primeiras posições: quanto menor, maior a vantagem do topo de cada ranking sobre as posições seguintes.

O valor de $k$ foi escolhido no conjunto dev, entre 10, 60 e 100, pelo maior NDCG\@10 médio (script `tune_hybrid.py`), com o lexical e o semântico já configurados.

#figure(
  {
    set par(justify: false)
    set text(size: 9pt)
    table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      table.header([*$k$*], [*P\@10*], [*R\@10*], [*MAP\@10*], [*NDCG\@10*]),
      [*10*], [*0,2627*], [0,1485], [*0,1067*], [*0,3299*],
      [60], [0,2596], [*0,1502*], [0,1060], [0,3273],
      [100], [0,2593], [0,1500], [0,1058], [0,3273],
    )
  },
  caption: [Ajuste do $k$ do RRF no conjunto dev (324 consultas). No mesmo conjunto, o lexical tem NDCG\@10 de 0,2906 e o semântico, 0,3024.],
) <tab-rrf-dev>

O valor selecionado foi $k = 10$, mantido na avaliação final no conjunto test. As diferenças entre os três valores são pequenas (0,0026 de NDCG\@10), e $k = 60$ e $k = 100$ produzem resultados quase idênticos, porque, com $k$ grande, $1\/(k + "rank")$ varia pouco entre as posições. Os três valores superam com folga os dois sistemas isolados no dev.
