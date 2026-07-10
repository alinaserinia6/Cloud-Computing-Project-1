
#import "assets/utils.typ"
#import "assets/resources.typ"

#import "chapters/title.typ"
#import "chapters/chapter-1.typ"

#set page(
  paper: "a4",
  margin: (x: 2.6cm, y: 2.6cm),
)

#set par(
  spacing: 0.3cm,
  leading: 0.4cm,
  first-line-indent: 0.4cm,
  justify: true,
)

#set text(
  font: "IRNazanin",
  size: 12pt,
  spacing: 0.3em,
)

#import "@preview/auto-bidi:0.1.0": *
#show: auto-dir.with(
  default-lang: "fa",
  detect-by: "first",
  // detect-by: "auto",
  base-font: "IRNazanin",
  english-font: "IRNazanin",
  arabic-script-lang: "fa",
)

#show footnote.entry: set text(dir: ltr, size: 12pt)

#set footnote(numbering: utils.footnote_numbering)

#set footnote.entry(
  indent: 0pt,
  clearance: 8pt,
  separator: [
    #line(length: 30% + 0pt, stroke: 0.5pt) #v(0.2%)
  ],
)

#set list(indent: 0.8cm)

#show math.equation: set text(size: 11pt)

#title
#pagebreak()

#context counter(page).update(1)
#set page(numbering: "۱")

#context counter(footnote).update(0)
#chapter-1
