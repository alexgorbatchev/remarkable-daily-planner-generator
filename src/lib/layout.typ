#import "../config.typ" as config
#import "calendar.typ": *
#import "link.typ": styled_link
#import "holidays.typ" as special_dates

#let fmt2(n) = if n < 10 { "0" + str(n) } else { str(n) }

// Same-date navigation shared by all three daily page types.
#let page-navigation(year, month, day, current, calendar-target) = {
  let day_name = get-weekday(year, month, day, short: true)
  let special_date = special_dates.special-date-entry(config.special_dates, month, day)
  let destinations = (
    (kind: "day", title: day_name, target: make-day-label),
    (kind: "notes", title: "Notes", target: make-notes-label),
    (kind: "standup", title: "Standup", target: make-standup-label),
  )
  let cells = (
    text(size: config.header.date_font_size, weight: "bold")[
      #styled_link(label(calendar-target), [#year], padding: 2pt) #get-month(month, short: true) #fmt2(day)
    ],
  )
  for destination in destinations {
    let title = [#destination.title]
    if destination.kind == current {
      title = text(fill: white, bottom-edge: "bounds", title)
    }
    let tab = if destination.kind == "standup" and not config.STANDUP_ENABLED {
      title
    } else {
      let target = destination.target
      styled_link(
        label(target(year, month, day)),
        title,
        padding: if destination.kind == current { 4pt } else { 2pt },
        fill: if destination.kind == current { black } else { none },
      )
    }
    if destination.kind == "day" {
      tab = text(size: config.header.weekday_font_size, tab)
      if (special_date != none) and (special_date.label != none) and (special_date.label != "") {
        tab = grid(
          columns: (auto,),
          row-gutter: 1mm + 2pt,
          tab,
          text(size: config.header.day_label_font_size)[#special_date.label],
        )
      }
    }
    cells.push(tab)
  }
  text(size: config.header.navigation_font_size)[
    #grid(columns: (auto, auto, auto, auto), align: left + top, column-gutter: 4mm, ..cells)
  ]
}

#let next-day(year, month, day) = {
  if day < days-in-month(year, month) {
    (year: year, month: month, day: day + 1)
  } else if month < 12 {
    (year: year, month: month + 1, day: 1)
  } else {
    (year: year + 1, month: 1, day: 1)
  }
}

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

#let quick-jump-row(year, month, day, label-fn) = {
  if not config.header.quick_jump_show { return none }

  let count = config.header.quick_jump_count
  if count <= 0 { return none }

  let date-cell(year, month, day) = {
    let label_text = quick-jump-label(year, month, day)
    let target = label(label-fn(year, month, day))
    grid.cell(align: left)[
      #set text(size: config.header.quick_jump_font_size, fill: luma(config.header.quick_jump_color))
      #styled_link(target, [#label_text], padding: 2pt)
    ]
  }

  let cells = ()
  let previous = datetime(year: year, month: month, day: day) - duration(days: 1)
  while previous.year() == year {
    if config.calendar.weekends or previous.weekday() <= 5 {
      cells.push(date-cell(previous.year(), previous.month(), previous.day()))
      break
    }
    previous -= duration(days: 1)
  }
  let previous_count = cells.len()
  let cur = (year: year, month: month, day: day)

  while cells.len() < count + previous_count {
    cur = next-day(cur.year, cur.month, cur.day)
    if cur.year != year { break }

    // If weekends are excluded from the planner, skip weekends here too so
    // quick-jump links never point to non-existent pages.
    if (not config.calendar.weekends) and (monday-index(cur.year, cur.month, cur.day) >= 5) {
      continue
    }

    cells.push(date-cell(cur.year, cur.month, cur.day))
  }

  if cells.len() == 0 { return none }

  grid(
    columns: cells.len(),
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
  header-content: content,
  main-content: content,
  label-fn: make-day-label // Default to day label function
) = {
  let quick_jump = quick-jump-row(year, month, day, label-fn)

  // Generate link target using the provided label function
  let link_target = label-fn(year, month, day)
  
  // Use a grid container with rows
  grid(
    rows: (config.header.height, 1fr), // Fixed header height, content fills the rest
    row-gutter: 0mm,
    
    // Header row with fixed height and top alignment
    align(top)[
      #{
        let header_main = pad(
          left: config.header.menu_margin_left - config.page.margin_x,
          right: config.header.menu_margin_right - config.page.margin_x,
        )[
          #header-content
        ]

        pad(
          top: config.header.top_gap,
          grid(
            columns: (1fr,),
            rows: (config.header.quick_jump_height, auto),
            row-gutter: 0mm,
            pad(
              left: config.header.menu_margin_left - config.page.margin_x,
              align(left + top, quick_jump),
            ),
            header_main,
          ),
        )
      }
      
      #label(link_target)
    ],
    
    // Main content row (fills remaining space)
    main-content
  )
}
