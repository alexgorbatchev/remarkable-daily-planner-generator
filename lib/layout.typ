#import "../config.typ": config
#import "calendar.typ": *
#import "link.typ": styled_link

// Font size constants removed - now in config

// Generic page layout with header and main content
#let page-layout(
  year: int,
  month: int, 
  day: int,
  header-right: content,
  main-content: content,
  label-fn: make-day-label // Default to day label function
) = {
  let day_name = get-weekday(year, month, day, short: false)
  let month_abbrev = get-month(month, short: true)
  let week_num = get-week-number(year, month, day)

  // Generate link target using the provided label function
  let link_target = label-fn(year, month, day)
  
  // Use a grid container with rows
  grid(
    rows: (config.header.height, 1fr), // Fixed header height, content fills the rest
    row-gutter: 0mm,
    
    // Header row with fixed height and top alignment
    align(top)[
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
              #text(size: config.header.date_font_size, weight: "bold")[#month_abbrev #day]
            ],
            [
              #text(size: config.header.weekday_font_size)[#day_name]
            ],
          )
        ],

        // Right side: Custom header content
        header-right,
      )#label(link_target)
    ],
    
    // Main content row (fills remaining space)
    main-content
  )
}