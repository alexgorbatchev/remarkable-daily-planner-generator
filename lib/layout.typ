#import "../config.typ" as config
#import "calendar.typ": *
#import "link.typ": styled_link
#import "holidays.typ" as special_dates

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

  let special_date = special_dates.special-date-entry(config.special_dates, month, day)
  let weekday_label = if (special_date != none) and (special_date.label != none) and (special_date.label != "") {
    [
      #day_name
      #h(1mm)
      #text(size: config.header.day_label_font_size)[#special_date.label]
    ]
  } else {
    [#day_name]
  }

  // Generate link target using the provided label function
  let link_target = label-fn(year, month, day)
  
  // Use a grid container with rows
  grid(
    rows: (config.header.height, 1fr), // Fixed header height, content fills the rest
    row-gutter: 0mm,
    
    // Header row with fixed height and top alignment
    align(top)[
      #pad(
        left: config.header.menu_margin_left - config.page.margin_x, 
        right: config.header.menu_margin_right - config.page.margin_x
      )[
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
                #text(size: config.header.weekday_font_size)[#weekday_label]
              ],
            )
          ],

          // Right side: Custom header content
          header-right,
        )
      ]
      
      #label(link_target)
    ],
    
    // Main content row (fills remaining space)
    main-content
  )
}