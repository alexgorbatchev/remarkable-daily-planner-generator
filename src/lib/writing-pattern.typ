// Shared backgrounds for Notes, Standup, and the Day writing sections.
#let writing-pattern(size, settings, rows: auto) = {
  assert(("lines", "grid", "none").any(it => it == settings.pattern), message: "writing.pattern must be lines, grid, or none")
  if settings.pattern == "none" { return none }
  assert(settings.spacing > 0pt, message: "writing.spacing must be positive")
  let stroke = (paint: luma(settings.color), thickness: settings.thickness, dash: settings.style)
  if settings.pattern == "grid" {
    let width = calc.min(calc.floor(size.width / settings.spacing) * settings.spacing + 1mm, size.width)
    let height = calc.min(calc.floor(size.height / settings.spacing) * settings.spacing + 1mm, size.height)
    let fill = tiling(size: (settings.spacing, settings.spacing))[
      #place(line(start: (0%, 0%), end: (0%, 100%), stroke: stroke))
      #place(line(start: (0%, 0%), end: (100%, 0%), stroke: stroke))
    ]
    align(center + top, pad(-0.3mm, rect(fill: fill, width: width, height: height)))
  } else {
    let intervals = if rows == auto { int(calc.floor(size.height / settings.spacing)) } else { rows }
    for index in range(0, intervals + 1) {
      place(top + left, dy: calc.min(index * settings.spacing, size.height), line(length: size.width, stroke: stroke))
    }
  }
}
