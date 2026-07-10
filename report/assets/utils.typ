
#import "resources.typ"

#let alphabet_numbering = (page_number, ..) => {
  resources.persian_letters.at(page_number - 1)
}

#let toc-entry(title, label) = context {
  let loc = locate(label)
  let nums = counter(page).at(loc)

  box([
    #title
    #box(width: 1fr, repeat[.])
    #link(loc, numbering(loc.page-numbering(), ..nums))
  ])
}

#let footnote_numbering = note_number => {
  let note_digits = str(note_number).split("").slice(1, -1)

  let altered_number = note_digits
    .map(
      digit => resources.persian_digits.at(
        int(digit),
      ),
    )
    .join("")

  altered_number + h(0.1%)
}

