
// Import layout function
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

// Function to create a 5mm grid pattern
#let grid-pattern() = {
  let grid = tiling(size: (5mm, 5mm))[
    #place(line(start: (0%, 0%), end: (0%, 100%), stroke: (paint: luma(200), dash: "dotted")))
    #place(line(start: (0%, 0%), end: (100%, 0%), stroke: (paint: luma(200), dash: "dotted")))
  ]

  pad(-0.3mm, 
    rect(fill: grid, width: 100%, height: 100%)
  )
}

// Main daily notes function
#let daily-notes(
  year: int,
  month: int,
  day: int,
) = {
  page-layout(
    year: year, 
    month: month, 
    day: day,
    label-fn: make-notes-label, // Use notes label instead of day label
    header-right: [
      #grid(
        columns: (auto, auto),
        align: (left + bottom, left + bottom),
        column-gutter: 5mm,
        [
          #text(size: FONT_SIZE_MEDIUM)[#styled_link(label(make-day-label(year, month, day)), [Day])]
        ],
        [
          #text(size: FONT_SIZE_MEDIUM)[#year]
        ],
      )
    ],
    main-content: grid-pattern()
  )
}
