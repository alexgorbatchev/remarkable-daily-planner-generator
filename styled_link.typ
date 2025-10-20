// Make links have larger clickable area without affecting the layout
#let styled_link(target, content) = {
  let padding = 5pt

  box(inset: -padding, link(target)[
    #box(inset: padding, content)
  ])
}

#let link = styled_link
