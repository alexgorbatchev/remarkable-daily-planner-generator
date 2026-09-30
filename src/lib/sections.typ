#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let checkbox(section) = {
  if section.checkbox_show {
    rect(width: section.checkbox_size, height: section.checkbox_size, stroke: (paint: luma(section.checkbox_color), thickness: 0.5pt), fill: none)
  }
}

#let checkbox-row(section, width: 100%) = {
  if not section.checkbox_show { return none }
  let cols = section.at("columns", default: 1)
  if cols < 1 { cols = 1 }
  let grid_cols = ()
  let items = ()
  for _ in range(0, cols) {
    grid_cols.push(1fr)
    items.push(align(left)[#checkbox(section)])
  }
  block(width: width)[
    #grid(columns: grid_cols, align: left, column-gutter: 0mm, ..items)
  ]
}

#let writing-line(section, width: 100%) = {
  line(length: width, stroke: (paint: luma(section.lines_color), thickness: 0.6pt, dash: section.lines_style))
}

// Draw a titled writing section with optional checkboxes.
#let section-with-lines(section) = {
  block(spacing: 0pt)[
    #text(size: section.title_font_size, weight: "bold")[#section.title_label]
  ]
  v(2mm)
  writing-line(section)
  for i in range(section.lines_count) {
    if section.checkbox_show {
      let spacing = (section.lines_height - section.checkbox_size) / 2
      v(spacing)
      block(spacing: 0mm)[#checkbox-row(section)]
      v(spacing)
      block(spacing: 0mm)[#writing-line(section)]
    } else {
      v(section.lines_height)
      block(spacing: 0mm)[#writing-line(section)]
    }
  }
}
