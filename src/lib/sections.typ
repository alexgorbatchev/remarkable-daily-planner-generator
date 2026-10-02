#import "writing-pattern.typ": writing-pattern

#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let checkbox(section) = {
  if section.checkbox_show {
    rect(width: section.checkbox_size, height: section.checkbox_size, stroke: (paint: luma(section.checkbox_color), thickness: 0.5pt), fill: white)
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

// Draw a titled writing area with optional checkboxes centered in each row.
#let writing-section(section) = {
  block(spacing: 0pt)[
    #text(size: section.title_font_size, weight: "bold")[#section.title_label]
  ]
  v(2mm)
  block(width: 100%, height: section.lines_count * section.writing.spacing)[
    #layout(size => writing-pattern(size, section.writing, rows: section.lines_count))
    #if section.checkbox_show {
      for index in range(section.lines_count) {
        let offset = index * section.writing.spacing + (section.writing.spacing - section.checkbox_size) / 2
        place(top + left, dy: offset, checkbox-row(section))
      }
    }
  ]
}
