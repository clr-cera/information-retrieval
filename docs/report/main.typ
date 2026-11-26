#import "@preview/quill-assignment:0.1.0": *

// Rótulos da capa em português (o template os define fixos em inglês).
#show "STUDENT": "AUTORES"
#show "INSTRUCTOR": "PROFESSOR"
#show "DATE": "DATA"
#show "TERM": "SEMESTRE"
#show "INSTITUTION": "INSTITUIÇÃO"
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
  cover-page: false,  // cabeçalho na primeira página, em vez de uma capa inteira (economiza espaço)
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


// Seção provisória: apagar inteira antes da entrega.
#heading(numbering: none)[O QUE FALTA FAZER]

#block(width: 100%, inset: 10pt, radius: 4pt, stroke: 1pt + rgb("#bf616a"), fill: rgb("#bf616a").lighten(92%))[
  #set par(justify: false)
  Esta seção é só um lembrete para o grupo e deve ser apagada antes da entrega (está no início do `main.typ`). Os passos detalhados estão em `docs/PENDENCIAS.md`.

  + *Avaliação humana do RAG.* Cada integrante preenche a sua planilha em `result/tp2/rag_avaliacao/`, sem abrir a chave antes de terminar. Cada uma das 20 respostas recebe nota 0, 1 ou 2 em fidelidade, completude, utilidade e rastreabilidade, com justificativa. Depois, rodar `evaluate_rag.py merge` com as duas planilhas e `check_results.py`.
  + *Resultados › RAG.* Preencher a tabela de médias da avaliação humana com os valores de `rag_evaluation_summary.md` e acrescentar a concordância entre os avaliadores. Discutir o efeito da recuperação na fidelidade e na disponibilidade de evidências e a falta de fontes nas respostas sem RAG.
  + *Análise de falhas.* Escolher pelas notas mais dois casos e analisá-los no mesmo formato do PLAIN-2850: uma consulta em que o RAG melhorou claramente a resposta e uma em que houve pouca diferença.
  + *Considerações finais.* Acrescentar a conclusão da avaliação humana do RAG.
  + *Cabeçalho.* Trocar os emails provisórios pelos emails reais.
  + *Uso de ferramentas de IA.* Revisar o rascunho e completar com o uso de cada integrante.
  + *Revisão final.* Apagar os comentários `// TODO` e esta seção, recompilar, conferir o limite de 20 páginas e ler o PDF inteiro.
  + *Entrega.* Fazer o commit e montar o `.zip` para o Moodle com o código, `result/tp2/` e este PDF. Não incluir `data/`, `.venv/`, `result/tp2/old_k2_b0/` nem chaves.
]

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

#heading(numbering: none)[Referências]

#set par(justify: false)
#set text(size: 9.5pt)

- MANNING, C. D.; RAGHAVAN, P.; SCHÜTZE, H. _Introduction to Information Retrieval_. Cambridge University Press, 2008.
- ROBERTSON, S.; ZARAGOZA, H. The Probabilistic Relevance Framework: BM25 and Beyond. _Foundations and Trends in Information Retrieval_, v. 3, n. 4, p. 333–389, 2009.
- THAKUR, N. et al. BEIR: A Heterogeneous Benchmark for Zero-shot Evaluation of Information Retrieval Models. _NeurIPS Datasets and Benchmarks_, 2021.
- BOTEVA, V. et al. A Full-Text Learning to Rank Dataset for Medical Information Retrieval (NFCorpus). _ECIR_, 2016.
- REIMERS, N.; GUREVYCH, I. Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks. _EMNLP_, 2019.
- WANG, W. et al. MiniLM: Deep Self-Attention Distillation for Task-Agnostic Compression of Pre-Trained Transformers. _NeurIPS_, 2020.
- NOGUEIRA, R.; CHO, K. Passage Re-ranking with BERT. _arXiv:1901.04085_, 2019.
- CORMACK, G. V.; CLARKE, C. L. A.; BÜTTCHER, S. Reciprocal Rank Fusion Outperforms Condorcet and Individual Rank Learning Methods. _SIGIR_, 2009.
- LEWIS, P. et al. Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks. _NeurIPS_, 2020.
- QWEN TEAM. Qwen3 Technical Report. _arXiv:2505.09388_, 2025.
- MACAVANEY, S.; MACDONALD, C.; OUNIS, I. Streamlining Evaluation with ir-measures. _ECIR_, 2022.
