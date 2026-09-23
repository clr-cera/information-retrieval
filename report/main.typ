#import "@preview/quill-assignment:0.1.0": *

#show: assignment.with(
  title: "Desenvolvimento e Análise de Modelos Claśsicos de Recuperação de Informação",
  course: "SCC0282 Recuperação de Informação",
  assignment: "Trabalho Prático 1",
  student: "Ariel Alves da Silva (8847378)\nStudent 2 (student2_id)",
  university: "Universidade de São Paulo",
  date: datetime.today(),
  cover-page: true,
)

#outline()

= Introdução

#include("./chapters/introduction.typ")

= Técnicas utilizadas

#include("./chapters/techniques.typ")

= Avaliação dos modelos

#include("./chapters/evaluation.typ")

= Resultados obtidos e Análise

#include("./chapters/analysis/vec_vs_prob.typ")
#include("./chapters/analysis/by_query.typ")
#include("./chapters/analysis/bm25_var.typ")
#include("./chapters/analysis/query_modifying.typ")
#include("./chapters/analysis/error_analysis.typ")

= Conclusão

#include("./chapters/conclusion.typ")

= Uso de ferramentas de IA

#include("./chapters/ai_use.typ")
