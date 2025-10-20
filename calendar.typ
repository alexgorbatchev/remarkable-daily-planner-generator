
// Import calendar helper functions
#import "calendar-helpers.typ": *



#let month-cells(y, m, highlight_day: int) = {
  let dim = days-in-month(y, m)
  let offset = monday-index(y, m, 1)
  let total = offset + dim
  let weeks = int(calc.ceil(total / 7))
  let cells = ()

  for _ in range(0, offset) { cells.push([]) }
  for d in range(1, dim + 1) {
    if d == highlight_day {
      cells.push(table.cell(fill: black)[
        #set text(fill: white)
        #d
      ])
    } else {
      cells.push([#d])
    }
  }
  let need = weeks * 7 - total
  for _ in range(0, need) { cells.push([]) }

  cells
}

#let month-view(
  year: int, month: int, title: auto,
  inset: 6pt, stroke: 0.5pt, title_size: 12pt,
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
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  )

  let cells = ()
  for m in range(1, 13) {
    let hl = if (selected != ()) and (selected.at(0) == year) and (selected.at(1) == m) {
        selected.at(2)
      } else { 0 }

    cells.push(
      scale(x: factor, y: factor, reflow: true)[
        #month-view(
          year: year, month: m, title: months.at(m - 1) + " " + str(year),
          inset: 3pt, stroke: 0.25pt, title_size: 11pt,
          highlight_day: hl,
        )
      ]
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


