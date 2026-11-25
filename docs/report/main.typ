#import "@preview/quill-assignment:0.1.0": *

// Rótulos da capa em português (o template os define fixos em inglês).
#show "STUDENT": "AUTORES"
#show "INSTRUCTOR": "PROFESSOR"
#show "DATE": "DATA"
#show "TERM": "SEMESTRE"
// Sem justificação nas grades (metadados da capa, cabeçalho e rodapé), que têm colunas estreitas.
#show grid: set par(justify: false)

#let meses = ("janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro")
#let hoje = datetime.today()

// TODO: substituir os emails placeholder antes da entrega (o enunciado exige email no cabeçalho).
#show: assignment.with(
  title: "Busca Lexical, Semântica, Híbrida, Reranking e RAG sobre o NFCorpus",
  subtitle: "Emails: <email Ariel> · <email Clara>",
  course: "SCC0282 Recuperação de Informação",
  assignment: "Trabalho Prático 2",
  student: "Ariel Alves da Silva (8847378)\nClara Ernesto de Carvalho (14559479)",
  instructor: "Prof. Marcelo Manzato",
  department: "Instituto de Ciências Matemáticas e de Computação (ICMC)",
  university: "Universidade de São Paulo",
  date: str(hoje.day()) + " de " + meses.at(hoje.month() - 1) + " de " + str(hoje.year()),
  cover-page: true,
)

#set text(lang: "pt", region: "br")

// Títulos numerados (1, 1.1, 1.1.1). O template mostra só o texto do título,
// então os três níveis são redefinidos aqui com o mesmo estilo e as cores do tema.
#set heading(numbering: "1.1")
#let numero(it) = if it.numbering != none { counter(heading).display(it.numbering) + h(0.6em) }
#show heading.where(level: 1): it => context {
  let th = active-theme.get()
  block(width: 100%, below: 1em, above: 1.8em)[
    #set text(fill: th.primary, size: 13.5pt, weight: "bold")
    #numero(it)#it.body
    #v(0.35em)
    #line(length: 100%, stroke: 0.6pt + th.border)
  ]
}
#show heading.where(level: 2): it => context {
  let th = active-theme.get()
  block(below: 0.8em, above: 1.4em)[
    #set text(fill: th.primary.darken(10%), size: 11.5pt, weight: "bold")
    #numero(it)#it.body
  ]
}
#show heading.where(level: 3): it => context {
  let th = active-theme.get()
  block(below: 0.6em, above: 1.1em)[
    #set text(fill: th.text, size: 10.5pt, weight: "bold")
    #numero(it)#it.body
  ]
}

#outline(depth: 2)

= Introdução

#include("./chapters/introduction.typ")

= Metodologia

#include("./chapters/methodology/preprocessing.typ")
#include("./chapters/methodology/inverted_index.typ")
#include("./chapters/methodology/lexical.typ")
#include("./chapters/methodology/typo_tolerance.typ")
#include("./chapters/methodology/semantic.typ")
#include("./chapters/methodology/hybrid.typ")
#include("./chapters/methodology/reranking.typ")
#include("./chapters/methodology/rag.typ")

= Avaliação

#include("./chapters/evaluation.typ")

= Resultados Obtidos e Análise

#include("./chapters/results/lexical_vs_semantic.typ")
#include("./chapters/results/typo_tolerance.typ")
#include("./chapters/results/hybrid.typ")
#include("./chapters/results/reranking.typ")
#include("./chapters/results/timing.typ")
#include("./chapters/results/rag.typ")
#include("./chapters/results/failure_analysis.typ")

= Considerações Finais

#include("./chapters/conclusion.typ")

= Uso de ferramentas de IA

#include("./chapters/ai_use.typ")
