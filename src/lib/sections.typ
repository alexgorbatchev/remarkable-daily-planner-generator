#import "writing-pattern.typ": writing-pattern, grid-geometry

#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let checkbox(section) = {
  if section.checkbox_show {
    rect(width: section.checkbox_size, height: section.checkbox_size, stroke: (paint: luma(section.checkbox_color), thickness: 0.5pt), fill: white)
  }
}

#let checkbox-row(section, width) = {
  if not section.checkbox_show { return none }
  let cols = section.at("columns", default: 1)
  if cols < 1 { cols = 1 }
  let body = if section.writing.pattern == "grid" {
    let spacing = section.writing.spacing
    let geometry = grid-geometry((width: width, height: spacing), spacing)
    let cells = int(calc.floor(width / spacing))
    for index in range(cols) {
      let cell = calc.floor(index * cells / cols)
      let offset = geometry.left + cell * spacing + (spacing - section.checkbox_size) / 2
      place(top + left, dx: offset, checkbox(section))
    }
  } else {
    let items = range(cols).map(_ => align(left, checkbox(section)))
    grid(columns: (1fr,) * cols, align: left, column-gutter: 0mm, ..items)
  }
  box(width: width, height: section.checkbox_size, body)
}

#let section-writing-body(size, section) = {
  writing-pattern(size, section.writing, rows: section.lines_count)
  if section.checkbox_show {
    let top_offset = if section.writing.pattern == "grid" { grid-geometry(size, section.writing.spacing).top } else { 0mm }
    for index in range(section.lines_count) {
      let offset = top_offset + index * section.writing.spacing + (section.writing.spacing - section.checkbox_size) / 2
      place(top + left, dy: offset, checkbox-row(section, size.width))
    }
  }
}

// Draw a titled writing area with optional checkboxes centered in each row.
#let writing-section(section) = {
  block(spacing: 0pt)[
    #text(size: section.title_font_size, weight: "bold")[#section.title_label]
  ]
  v(2mm)
  block(width: 100%, height: section.lines_count * section.writing.spacing)[
    #layout(size => section-writing-body(size, section))
  ]
}
