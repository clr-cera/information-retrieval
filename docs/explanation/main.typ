// Explicação do projeto do Trabalho Prático 2.
// Compilar com: typst compile docs/explanation/main.typ

#set document(title: "TP2 de Recuperação de Informação — explicação do projeto")
#set page(paper: "a4", margin: (x: 2.2cm, y: 2.4cm), numbering: "1")
#set text(lang: "pt", region: "br", size: 10.5pt)
#set par(justify: true, leading: 0.68em)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  set text(size: 17pt, fill: rgb("#2f5d8a"))
  block(below: 1em, it)
}
#show heading.where(level: 2): set text(size: 13pt, fill: rgb("#2f5d8a"))
#show heading.where(level: 3): set text(size: 11pt)
#show raw.where(block: true): it => block(
  width: 100%,
  fill: luma(246),
  inset: 8pt,
  radius: 3pt,
  text(size: 8.5pt, it),
)
#show raw.where(block: false): it => box(fill: luma(240), inset: (x: 2pt), outset: (y: 2pt), radius: 2pt, it)

#align(center)[
  #v(3cm)
  #text(size: 24pt, weight: "bold", fill: rgb("#2f5d8a"))[Recuperação de Informação \ Trabalho Prático 2]
  #v(0.6cm)
  #text(size: 15pt)[Explicação do projeto: conceitos, pipeline e arquivos]
  #v(1.2cm)
  #text(size: 11pt)[
    SCC0282 — Recuperação de Informação · ICMC/USP · 2º semestre de 2026 \
    Ariel Alves da Silva (8847378) · Clara Ernesto de Carvalho (14559479)
  ]
  #v(2cm)
  #block(width: 85%)[
    #set par(justify: true)
    #set text(size: 10pt)
    Este documento explica o projeto para quem cursa a disciplina: a teoria de cada técnica, o fluxo do pipeline, o papel de cada arquivo e os resultados. Ele não descreve função por função; para isso, o próprio código é a referência. Serve como guia de estudo para a defesa individual e como mapa para quem precisar modificar o código.
  ]
]

#pagebreak()
#outline(depth: 2, indent: auto)

#include "chapters/01_visao_geral.typ"
#include "chapters/02_estrutura.typ"
#include "chapters/03_metricas.typ"
#include "chapters/04_dados.typ"
#include "chapters/05_lexical.typ"
#include "chapters/06_correcao.typ"
#include "chapters/07_semantica.typ"
#include "chapters/08_hibrida_reranking.typ"
#include "chapters/09_rag.typ"
#include "chapters/10_scripts.typ"
#include "chapters/11_testes_resultados.typ"
#include "chapters/12_defesa.typ"
