

// Import layout function and calendar helpers
#import "lib/layout.typ": page-layout
#import "calendar-helpers.typ": *
#import "styled_link.typ": styled_link

// Remove default paragraph spacing  
#set par(leading: 0pt, spacing: 0pt)

// Remove default block spacing
#set block(spacing: 0pt)

// Global font size variables
#let FONT_SIZE_LARGE = 24pt
#let FONT_SIZE_MEDIUM = 12pt
#let FONT_SIZE_SMALL = 11pt

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
    #text(size: FONT_SIZE_SMALL, weight: "bold")[#title]
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
  todo_lines: 11,
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
          #text(size: FONT_SIZE_MEDIUM)[#styled_link(label(make-notes-label(year, month, day)), [Notes])]
        ],
        [
          #text(size: FONT_SIZE_MEDIUM)[#styled_link(label(CALENDAR_LABEL), [#year])]
        ],
      )
    ],
    main-content: [
      // Top priority section
      #section-with-lines(title: "Top priority", num_lines: priority_lines, with_checkboxes: false)

      #v(10mm)

      // To-dos section
      #section-with-lines(title: "Work", num_lines: todo_lines, with_checkboxes: true)

      #v(10mm)

      // Maybe/someday section
      #section-with-lines(title: "Other", num_lines: maybe_lines, with_checkboxes: true)
    ]
  )
}


