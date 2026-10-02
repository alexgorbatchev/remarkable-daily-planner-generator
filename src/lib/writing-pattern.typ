// Shared backgrounds for Notes, Standup, and the Day writing sections.
#let grid-geometry(size, spacing, rows: auto) = {
  let width = calc.min(calc.floor(size.width / spacing) * spacing + 1mm, size.width)
  let intervals = if rows == auto { int(calc.floor(size.height / spacing)) } else { rows }
  let height = calc.min(intervals * spacing + 1mm, size.height)
  let inset = -0.3mm
  (width: width, height: height, left: (size.width - width) / 2, top: inset, inset: inset)
}

#let horizontal-lines(size, spacing, stroke, rows: auto) = {
  let intervals = if rows == auto { int(calc.floor(size.height / spacing)) } else { rows }
  for index in range(0, intervals + 1) {
    place(top + left, dy: calc.min(index * spacing, size.height), line(length: size.width, stroke: stroke))
  }
}

#let writing-pattern(size, settings, rows: auto) = {
  assert(("lines", "grid", "none").any(it => it == settings.pattern), message: "writing.pattern must be lines, grid, or none")
  if settings.pattern == "none" { return none }
  assert(settings.spacing > 0pt, message: "writing.spacing must be positive")
  let stroke = (paint: luma(settings.color), thickness: settings.thickness, dash: settings.style)
  if settings.pattern == "grid" {
    let geometry = grid-geometry(size, settings.spacing, rows: rows)
    let grid = {
      horizontal-lines(geometry, settings.spacing, stroke, rows: rows)
      for index in range(0, int(calc.floor(geometry.width / settings.spacing)) + 1) {
        place(top + left, dx: index * settings.spacing, line(start: (0pt, 0pt), end: (0pt, geometry.height), stroke: stroke))
      }
    }
    align(center + top, pad(geometry.inset, box(width: geometry.width, height: geometry.height, grid)))
  } else {
    horizontal-lines(size, settings.spacing, stroke, rows: rows)
  }
}
