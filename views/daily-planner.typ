
#import "../config.typ" as config
#import "../lib/calendar.typ": *
#import "../lib/layout.typ": page-layout
#import "../lib/link.typ": styled_link

// Remove default paragraph spacing  
#set par(leading: 0pt, spacing: 0pt)

// Remove default block spacing
#set block(spacing: 0pt)

// Function to create a checkbox with configurable size and color
#let checkbox(section) = {
  if section.checkbox_show {
    rect(width: section.checkbox_size, height: section.checkbox_size, stroke: (paint: luma(section.checkbox_color), thickness: 0.5pt), fill: none)
  }
}

// Function to create a line for writing
#let writing-line(section, width: 100%) = {
  line(length: width, stroke: (paint: luma(section.lines_color), thickness: 0.6pt, dash: section.lines_style))
}

// Function to create a section with lines
#let section-with-lines(section) = {
  // Section header with underline
  block(spacing: 0pt)[
    #text(size: section.title_font_size, weight: "bold")[#section.title_label]
  ]
  v(2mm)
  writing-line(section)

  // Lines with optional checkboxes
  for i in range(section.lines_count) {
    if section.checkbox_show {
      let spacing = (section.lines_height - section.checkbox_size) / 2
      v(spacing)
      block(spacing: 0mm)[#checkbox(section)]
      v(spacing)
      block(spacing: 0mm)[#writing-line(section)]
    } else {
      v(section.lines_height)
      block(spacing: 0mm)[#writing-line(section)]
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
          #text(size: config.header.navigation_font_size)[#styled_link(label(make-notes-label(year, month, day)), [Notes])]
        ],
        [
          #text(size: config.header.navigation_font_size)[#styled_link(label(config.calendar_label), [#year])]
        ],
      )
    ],
    main-content: [
      #for section in config.daily_planner_sections [
        #section-with-lines(section)
        #v(5mm)
      ]
    ]
  )
}


