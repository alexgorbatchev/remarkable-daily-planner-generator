
#import "../config.typ": config
#import "../lib/calendar.typ": *
#import "../lib/link.typ": styled_link


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
    // Generate link target using helper function
    let link_target = make-day-label(y, m, d)
    let day_content = styled_link(label(link_target), [#d])

    if d == highlight_day {
      cells.push(table.cell(fill: black)[
        #set text(fill: white)
        #day_content
      ])
    } else {
      cells.push([#day_content])
    }
  }
  let need = weeks * 7 - total
  for _ in range(0, need) { cells.push([]) }

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
  let days = ("M", "T", "W", "T", "F", "S", "S")
  let header = days.map(d => table.cell(stroke: (bottom: 0.5pt))[*#d*])

  // which table row holds the highlighted day? (0=title, 1=weekday header)
  let dim = days-in-month(year, month)
  let offset = monday-index(year, month, 1)
  let y_highlight = if (highlight_day >= 1) and (highlight_day <= dim) {
    2 + floor-div(offset + (highlight_day - 1), 7)
  } else { -1 }

  let body = month-cells(year, month, highlight_day: highlight_day)

  table(
    columns: 7,
    stroke: none,
    inset: (x: 1.7mm, y: 2mm),
    align: center + top,
    // highlight only the row containing the selected date
    fill: (x, y) => if y == y_highlight { luma(235) } else { white },
    table.cell(colspan: 7, stroke: none, align: center + top)[
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
    #text(size: 18pt, weight: "bold", spacing: 0mm)[#year]#label(config.calendar_label)
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
    row-gutter: 8mm,
    column-gutter: 5mm,
    ..cells,
  )
}


