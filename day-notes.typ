
// Import calendar helper functions
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

// Function to create the header section (same as day.typ)
#let day-header(year: int, month: int, day: int) = {
  let day_name = get-weekday(year, month, day, short: false)
  let month_abbrev = get-month(month, short: true)
  let week_num = get-week-number(year, month, day)

  // Generate link target using helper function
  let link_target = make-day-label(year, month, day)
  
  // Header block with label attached
  block(below: 5mm)[
    #grid(
      columns: (1fr, auto),
      align: (left, right + bottom),

      // Left side: Date and day name
      [
        #grid(
          columns: (auto, auto),
          align: (left + bottom, left + bottom),  // Use bottom alignment for baseline
          column-gutter: 5mm,
          [
            #text(size: FONT_SIZE_LARGE, weight: "bold")[#month_abbrev #day]
          ],
          [
            #text(size: FONT_SIZE_MEDIUM)[#day_name]
          ],
        )
      ],

      // Right side: Year and week
      [
        #grid(
          columns: (auto, auto),
          align: (left + bottom, left + bottom),
          column-gutter: 5mm,
          [
            #text(size: FONT_SIZE_MEDIUM)[Week #week_num]
          ],
          [
            #text(size: FONT_SIZE_MEDIUM)[#year]
          ],
        )
      ],
    )#label(link_target)
  ]
}

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
  // Use a grid container with rows
  grid(
    rows: (auto, 1fr), // Header takes needed space, grid fills the rest
    row-gutter: 2mm,
    
    // Header row
    day-header(year: year, month: month, day: day),
    
    // Grid pattern row (fills remaining space)
    grid-pattern()
  )
}

// Page setup
#set page(
  width: 158mm,
  height: 210mm,
  margin: (
    top: 10mm,
    right: 5mm,
    bottom: 5mm,
    left: 5mm
  )
)

// Generate a sample day-notes page
#daily-notes(year: 2025, month: 10, day: 20)
