// Link styling - larger clickable area without affecting layout
#let styled_link(target, content, padding: 5pt, fill: none) = {
  box(inset: -padding, link(target)[
    #box(inset: padding, fill: fill, content)
  ])
}

#let link = styled_link
