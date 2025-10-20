
#import "../config.typ": config
#import "../lib/calendar.typ": *
#import "../lib/layout.typ": page-layout
#import "../lib/link.typ": styled_link

// Remove default paragraph spacing  
#set par(leading: 0pt, spacing: 0pt)

// Remove default block spacing
#set block(spacing: 0pt)

// Function to create a checkbox with configurable size and color
#let checkbox() = {
  rect(width: config.checkbox_size, height: config.checkbox_size, stroke: (paint: luma(config.checkbox_line_color), thickness: 0.5pt), fill: none)
}

// Function to create a line for writing
#let writing-line(width: 100%) = {
  line(length: width, stroke: (paint: luma(config.checkbox_line_color), thickness: 0.6pt, dash: "dotted"))
}

// Function to create a section with lines
#let section-with-lines(title: str, num_lines: int, with_checkboxes: false) = {
  // Section header with underline
  block(spacing: 0pt)[
    #text(size: config.font_size_small, weight: "bold")[#title]
  ]
  v(2mm)
  writing-line()

  // Lines with optional checkboxes
  for i in range(num_lines) {
    if with_checkboxes {
      let spacing = (config.line_height - config.checkbox_size) / 2
      v(spacing)
      block(spacing: 0mm)[#checkbox()]
      v(spacing)
      block(spacing: 0mm)[#writing-line()]
    } else {
      if i < num_lines - 1 { v(config.line_height) }
      block(spacing: 0mm)[#writing-line()]
    }
  }
}

// Main daily planner function
#let daily-planner(
  year: int,
  month: int,
  day: int,
) = {
  page-layout(
    year: year, 
    month: month, 
    day: day,
    header-right: [
      #grid(
        columns: (auto, auto),
        align: (left + bottom, left + bottom),
        column-gutter: 5mm,
        [
          #text(size: config.font_size_medium)[#styled_link(label(make-notes-label(year, month, day)), [Notes])]
        ],
        [
          #text(size: config.font_size_medium)[#styled_link(label(config.calendar_label), [#year])]
        ],
      )
    ],
    main-content: [
      #section-with-lines(title: "Top Priority", num_lines: config.priority_lines, with_checkboxes: false)
      #v(5mm)

      #section-with-lines(title: "Primary", num_lines: config.primary_lines, with_checkboxes: true)
      #v(5mm)

      #section-with-lines(title: "Secondary", num_lines: config.secondary_lines, with_checkboxes: true)
    ]
  )
}


