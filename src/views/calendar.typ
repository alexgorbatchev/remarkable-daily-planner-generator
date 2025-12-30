
#import "../config.typ" as config
#import "../lib/calendar.typ": *
#import "../lib/holidays.typ" as special_dates
#import "../lib/link.typ": styled_link

// Calendar navigation label
#let calendar_label = "calendar-view"

// Build a consistent-size clickable day label so 1-digit and 2-digit dates
// have the same hit area (and any overlays have consistent geometry).
#let day-content(year, month, day) = {
  let link_target = make-day-label(year, month, day)
  context {
    let w = measure([00]).width
    styled_link(
      label(link_target),
      [
        #box(width: w)[
          #align(center)[#day]
        ]
      ],
    )
  }
}

// Draw a diagonal strike over the content without changing its measured size.
// This keeps the calendar layout identical while still making the mark visible.
#let strike-overlay(content, inverted: false) = {

  context {
    let s = measure(content)

    // Keep the wrapper exactly the same size as the content so table layout
    // (row heights / column widths) doesn't change.
    let w = s.width
    let h = s.height

    block(width: w, height: h)[
      #place(
        center + horizon,
        content,
      )
      #place(
        top + left,
        line(
          start: (w, 0pt),
          end: (0pt, h),
          stroke: (
            paint: if inverted { white } else { luma(config.calendar.strike_color) },
            thickness: config.calendar.strike_thickness,
          ),
        ),
      )
    ]
  }
}

// Fade the content (without changing layout) to de-emphasize a date.
#let fade-content(content, inverted: false) = {
  // Keep this purely cosmetic: text fill changes don't affect layout metrics.
  let fill = luma(config.calendar.fade)
  [
    #set text(fill: fill)
    #content
  ]
}

#let highlighted-day-cell(content) = {
  table.cell(fill: black)[
    #set text(fill: white)
    #content
  ]
}

#let is-weekend(year, month, day) = monday-index(year, month, day) >= 5

#let business-day-pos(year, month, day) = {
  let dim = days-in-month(year, month)

  if (day < 1) or (day > dim) { return -1 }
  if is-weekend(year, month, day) { return -1 }

  let first = 1
  while (first <= dim) and is-weekend(year, month, first) {
    first += 1
  }

  if first > dim { return -1 }

  let offset = monday-index(year, month, first)
  let pos = offset

  for d in range(first, day) {
    if not is-weekend(year, month, d) {
      pos += 1
    }
  }

  pos
}

#let month-cells(y, m, highlight_day: int) = {
  let dim = days-in-month(y, m)
  let offset = monday-index(y, m, 1)
  let total = offset + dim
  let weeks = int(calc.ceil(total / 7))
  let cells = ()

  // Calculate day-of-year offset for this month
  let day_offset = 0
  for prev_month in range(1, m) {
    day_offset += days-in-month(y, prev_month)
  }

  for _ in range(0, offset) { cells.push([]) }
  for d in range(1, dim + 1) {
    let day_content = day-content(y, m, d)
    let special_date = special_dates.special-date-entry(config.special_dates, m, d)
    let style = if special_date != none { special_date.style } else { none }

    if d == highlight_day {
      if style == "strike" {
        cells.push(table.cell(fill: black)[
          #set text(fill: white)
          #strike-overlay(day_content, inverted: true)
        ])
      } else if style == "fade" {
        cells.push(table.cell(fill: black)[
          #fade-content(day_content, inverted: true)
        ])
      } else {
        cells.push(highlighted-day-cell(day_content))
      }
    } else {
      cells.push([
        #if style == "strike" { strike-overlay(day_content) } else if style == "fade" { fade-content(day_content) } else { day_content }
      ])
    }
  }
  let need = weeks * 7 - total
  for _ in range(0, need) { cells.push([]) }

  cells
}

#let month-cells-business(y, m, highlight_day: int) = {
  let dim = days-in-month(y, m)
  let cells = ()

  // Find first business day so we can compute the leading offset.
  let first = 1
  while (first <= dim) and is-weekend(y, m, first) {
    first += 1
  }

  if first > dim {
    // Degenerate case: no business days (shouldn't happen), return an empty grid.
    for _ in range(0, 5) { cells.push([]) }
    return cells
  }

  let offset = monday-index(y, m, first)
  for _ in range(0, offset) { cells.push([]) }

  for d in range(first, dim + 1) {
    if is-weekend(y, m, d) { continue }

    let day_content = day-content(y, m, d)
    let special_date = special_dates.special-date-entry(config.special_dates, m, d)
    let style = if special_date != none { special_date.style } else { none }

    if d == highlight_day {
      if style == "strike" {
        cells.push(table.cell(fill: black)[
          #set text(fill: white)
          #strike-overlay(day_content, inverted: true)
        ])
      } else if style == "fade" {
        cells.push(table.cell(fill: black)[
          #fade-content(day_content, inverted: true)
        ])
      } else {
        cells.push(highlighted-day-cell(day_content))
      }
    } else {
      cells.push([
        #if style == "strike" { strike-overlay(day_content) } else if style == "fade" { fade-content(day_content) } else { day_content }
      ])
    }
  }

  let rem = calc.rem(cells.len(), 5)
  if rem != 0 {
    for _ in range(0, 5 - rem) { cells.push([]) }
  }

  cells
}

#let month-view(
  year: int,
  month: int,
  title: auto,
  inset: 6pt,
  stroke: 0.5pt,
  title_size: 12pt,
  highlight_day: int,
) = {
  let columns = if config.calendar.weekends { 7 } else { 5 }
  let days = if config.calendar.weekends {
    ("M", "T", "W", "T", "F", "S", "S")
  } else {
    ("M", "T", "W", "T", "F")
  }
  let header = days.map(d => table.cell(stroke: (bottom: 0.5pt))[*#d*])

  // which table row holds the highlighted day? (0=title, 1=weekday header)
  let dim = days-in-month(year, month)
  let y_highlight = if config.calendar.weekends {
    let offset = monday-index(year, month, 1)
    if (highlight_day >= 1) and (highlight_day <= dim) {
      2 + floor-div(offset + (highlight_day - 1), 7)
    } else { -1 }
  } else {
    let pos = business-day-pos(year, month, highlight_day)
    if pos >= 0 { 2 + floor-div(pos, 5) } else { -1 }
  }

  let body = if config.calendar.weekends {
    month-cells(year, month, highlight_day: highlight_day)
  } else {
    month-cells-business(year, month, highlight_day: highlight_day)
  }

  table(
    columns: columns,
    stroke: none,
    inset: (x: 1.7mm, y: 2mm),
    align: center + top,
    // highlight only the row containing the selected date
    fill: (x, y) => if y == y_highlight { luma(235) } else { white },
    table.cell(colspan: columns, stroke: none, align: center + top)[
      #set text(weight: 700, size: title_size)
      #title
    ],
    ..header,
    ..body,
  )
}

#let year-view(year: int, factor: 85%, selected: ()) = {
  let months = (
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  )

  // Year heading with calendar label
  align(center)[
    #text(size: 18pt, weight: "bold", spacing: 0mm)[#year]#label(calendar_label)
  ]

  let cells = ()
  for m in range(1, 13) {
    let hl = if (selected != ()) and (selected.at(0) == year) and (selected.at(1) == m) {
      selected.at(2)
    } else { 0 }

    cells.push(
      scale(x: factor, y: factor, reflow: true)[
        #month-view(
          year: year,
          month: m,
          title: months.at(m - 1) + " " + str(year),
          inset: 3pt,
          stroke: 0.25pt,
          title_size: 11pt,
          highlight_day: hl,
        )
      ],
    )
  }

  table(
    columns: 3,
    stroke: none,
    align: center + top,
    inset: 0pt,
    row-gutter: 5mm,
    column-gutter: config.calendar.column_gap,
    ..cells,
  )
}


