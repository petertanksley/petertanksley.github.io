// Typst preamble for the two-page CV. Loaded via include-in-header.
#set text(font: "Helvetica Neue", size: 9.6pt, hyphenate: false)
#set par(justify: false, leading: 0.55em)
#show heading.where(level: 1): it => block(above: 1.0em, below: 0.45em)[
  #set text(size: 10.5pt, weight: "bold", tracking: 0.06em)
  #upper(it.body)
  #v(-0.35em)
  #line(length: 100%, stroke: 0.6pt + luma(120))
]
#show heading.where(level: 2): it => block(above: 0.7em, below: 0.3em)[
  #set text(size: 9.8pt, weight: "bold", style: "italic")
  #it.body
]
#show link: set text(fill: rgb("#1f5fa8"))
#set list(indent: 0.6em, body-indent: 0.5em, spacing: 0.5em)
#set enum(indent: 0.6em, body-indent: 0.5em, spacing: 0.5em)
