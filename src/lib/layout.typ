#import "../config.typ" as config
#import "calendar.typ": *
#import "link.typ": styled_link
#import "holidays.typ" as special_dates

#let next-day(year, month, day) = {
  if day < days-in-month(year, month) {
    (year: year, month: month, day: day + 1)
  } else if month < 12 {
    (year: year, month: month + 1, day: 1)
  } else {
    (year: year + 1, month: 1, day: 1)
  }
}

#let fmt2(n) = if n < 10 { "0" + str(n) } else { str(n) }

#let quick-jump-label(year, month, day) = {
  let fmt = config.header.quick_jump_format
  let out = fmt

  out = out.replace("{mon}", get-month(month, short: true))
  out = out.replace("{month}", get-month(month, short: false))
  out = out.replace("{day}", str(day))
  out = out.replace("{dd}", fmt2(day))
  out = out.replace("{m}", str(month))
  out = out.replace("{mm}", fmt2(month))
  out = out.replace("{dow}", get-weekday(year, month, day, short: true))
  out = out.replace("{weekday}", get-weekday(year, month, day, short: false))

  out
}

#let quick-jump-row(year, month, day) = {
  if not config.header.quick_jump_show { return none }

  let count = config.header.quick_jump_count
  if count <= 0 { return none }

  let columns = ()
  for _ in range(0, count) {
    columns.push(auto)
  }

  let cells = ()
  let cur = (year: year, month: month, day: day)

  while cells.len() < count {
    cur = next-day(cur.year, cur.month, cur.day)
    if cur.year != year { break }

    // If weekends are excluded from the planner, skip weekends here too so
    // quick-jump links never point to non-existent pages.
    if (not config.calendar.weekends) and (monday-index(cur.year, cur.month, cur.day) >= 5) {
      continue
    }

    let label_text = quick-jump-label(cur.year, cur.month, cur.day)
    let target = label(make-day-label(cur.year, cur.month, cur.day))

    cells.push(
      table.cell(align: left)[
        #set text(size: config.header.quick_jump_font_size, fill: luma(config.header.quick_jump_color))
        #styled_link(target, [#label_text])
      ]
    )
  }

  for _ in range(cells.len(), count) {
    cells.push(table.cell[])
  }

  table(
    columns: columns,
    stroke: none,
    inset: 0pt,
    align: left,
    column-gutter: config.header.quick_jump_gap,
    row-gutter: 0mm,
    ..cells,
  )
}

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

  let quick_jump = quick-jump-row(year, month, day)

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
      #{
        let weekday_cell_content = if quick_jump != none {
          grid(
            columns: (auto,),
            rows: (config.header.quick_jump_height, auto),
            row-gutter: 0mm,
            align: left,
            grid.cell(align: left + top)[
              #quick_jump
            ],
            grid.cell(align: left + bottom)[
              #text(size: config.header.weekday_font_size)[#weekday_label]
            ],
          )
        } else {
          text(size: config.header.weekday_font_size)[#weekday_label]
        }

        let header_main = pad(
          left: config.header.menu_margin_left - config.page.margin_x,
          right: config.header.menu_margin_right - config.page.margin_x,
        )[
          #grid(
            columns: (1fr, auto),
            rows: (auto,),
            row-gutter: 0mm,
            align: (left, right + bottom),
            // Left side: Date and day name
            [
              #grid(
                columns: (auto, auto),
                align: (left + bottom, left + bottom),
                column-gutter: 5mm,
                [
                  #text(size: config.header.date_font_size, weight: "bold")[#month_abbrev #day]
                ],
                [
                  #weekday_cell_content
                ],
              )
            ],
            // Right side: Custom header content
            header-right,
          )
        ]

        header_main
      }
      
      #label(link_target)
    ],
    
    // Main content row (fills remaining space)
    main-content
  )
}