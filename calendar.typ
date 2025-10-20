

#let is-leap(y) = (calc.rem(y, 4) == 0 and calc.rem(y, 100) != 0) or calc.rem(y, 400) == 0

#let days-in-month(y, m) = if m == 2 {
  if is-leap(y) { 29 } else { 28 }
} else if (m == 1) or (m == 3) or (m == 5) or (m == 7) or (m == 8) or (m == 10) or (m == 12) {
  31
} else {
  30
}

#let floor-div(a, b) = int((a - calc.rem(a, b)) / b)

// Zeller’s congruence (Gregorian calendar)
#let zeller-h(y, m, d) = {
  let mm = if m <= 2 { m + 12 } else { m }
  let yy = if m <= 2 { y - 1 } else { y }
  let K = int(calc.rem(yy, 100))
  let J = floor-div(yy, 100)
  let t1 = d
  let t2 = floor-div(13 * (mm + 1), 5)
  let t3 = K
  let t4 = floor-div(K, 4)
  let t5 = floor-div(J, 4)
  let t6 = 5 * J
  int(calc.rem(t1 + t2 + t3 + t4 + t5 + t6, 7))
}

// Convert to Monday=0 … Sunday=6
#let monday-index(y, m, d) = int(calc.rem(zeller-h(y, m, d) + 5, 7))

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


