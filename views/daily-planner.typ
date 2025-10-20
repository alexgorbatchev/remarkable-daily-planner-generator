
#import "../config.typ": config
#import "../lib/calendar.typ": *
#import "../lib/layout.typ": page-layout
#import "../lib/link.typ": styled_link

// Remove default paragraph spacing  
#set par(leading: 0pt, spacing: 0pt)

// Remove default block spacing
#set block(spacing: 0pt)

// Function to create a checkbox
#let checkbox() = {
  rect(width: 4mm, height: 4mm, stroke: 0.5pt, fill: none)
}

// Function to create a line for writing
#let writing-line(width: 100%) = {
  line(length: width, stroke: (paint: gray, thickness: 0.6pt, dash: "dotted"))
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
      v(2mm)
      block(spacing: 0mm)[#checkbox()]
      v(2mm)
      block(spacing: 0mm)[#writing-line()]
    } else {
      if i < num_lines - 1 { v(7mm) }
      block(spacing: 0mm)[#writing-line()]
    }
  }
}

// Main daily planner function
#let daily-planner(
  year: int,
  month: int,
  day: int,
  priority_lines: 3,
  todo_lines: 13,
  maybe_lines: 5,
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
      // space after the header
      #v(5mm)

      #section-with-lines(title: "Top Priority", num_lines: priority_lines, with_checkboxes: false)
      #v(5mm)

      #section-with-lines(title: "Primary", num_lines: todo_lines, with_checkboxes: true)
      #v(5mm)

      #section-with-lines(title: "Secondary", num_lines: maybe_lines, with_checkboxes: true)
    ]
  )
}


