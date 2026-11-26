// Elementos visuais compartilhados pelos capítulos da explicação.

#let cor-principal = rgb("#2f5d8a")
#let cor-suave = rgb("#eef3f8")
#let cor-alerta = rgb("#fff4e5")
#let cor-borda-alerta = rgb("#e0a040")

// Caixa de destaque para ideias importantes.
#let ideia(titulo: "Ideia central", corpo) = block(
  width: 100%,
  fill: cor-suave,
  stroke: (left: 3pt + cor-principal),
  inset: 10pt,
  radius: 3pt,
)[
  #text(weight: "bold", fill: cor-principal)[#titulo] \
  #corpo
]

// Caixa para cuidados, limitações e armadilhas.
#let atencao(titulo: "Atenção", corpo) = block(
  width: 100%,
  fill: cor-alerta,
  stroke: (left: 3pt + cor-borda-alerta),
  inset: 10pt,
  radius: 3pt,
)[
  #text(weight: "bold", fill: rgb("#8a5a00"))[#titulo] \
  #corpo
]

// Tabela simples com cabeçalho destacado.
#let tabela(colunas, ..celulas) = {
  set par(justify: false)
  set text(size: 9pt)
  table(
    columns: colunas,
    align: left,
    stroke: 0.5pt + luma(200),
    fill: (_, linha) => if linha == 0 { cor-suave } else { none },
    ..celulas,
  )
}
