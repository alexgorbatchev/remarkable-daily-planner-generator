
#import "../config.typ" as config
#import "../lib/layout.typ": page-layout
#import "../lib/calendar.typ": *
#import "../lib/link.typ": styled_link
#import "calendar.typ": calendar_label

// Remove default paragraph spacing  
#set par(leading: 0pt, spacing: 0pt)

// Remove default block spacing
#set block(spacing: 0pt)

// Function to create a configurable grid pattern that fits and centers in available space
#let grid-pattern() = {
  // Calculate available content area
  let content_width = config.page.width - 2 * config.page.margin_x
  let content_height = config.page.height - 2 * config.page.margin_y
  
  // Subtract header height
  let available_height = content_height - config.header.height
  
  // Calculate how many grid cells fit in each direction
  let cells_width = calc.floor(content_width / config.daily_notes.lines_size)
  let cells_height = calc.floor(available_height / config.daily_notes.lines_size)
  
  // Calculate actual grid dimensions
  let grid_width = cells_width * config.daily_notes.lines_size + 1mm
  let grid_height = cells_height * config.daily_notes.lines_size + 1mm
  
  // Create the grid pattern
  let grid = tiling(size: (config.daily_notes.lines_size, config.daily_notes.lines_size))[
    #place(line(start: (0%, 0%), end: (0%, 100%), stroke: (paint: luma(config.daily_notes.lines_color), dash: "dotted")))
    #place(line(start: (0%, 0%), end: (100%, 0%), stroke: (paint: luma(config.daily_notes.lines_color), dash: "dotted")))
  ]

  // Center the grid in available space
  align(center + top)[
    #pad(-0.3mm, 
      rect(fill: grid, width: grid_width, height: grid_height)
    )
  ]
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
          #text(size: config.header.navigation_font_size)[#styled_link(label(make-day-label(year, month, day)), [Day])]
        ],
        [
          #text(size: config.header.navigation_font_size)[#styled_link(label(calendar_label), [#year])]
        ],
      )
    ],
    main-content: grid-pattern()
  )
}
