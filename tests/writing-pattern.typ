#import "../src/config.typ" as config
#import "../src/lib/writing-pattern.typ": writing-pattern
#import "../src/lib/sections.typ": writing-section
#import "../src/views/daily-notes.typ": daily-notes
#import "helpers.typ": descendants

// Inspect generated shapes and positions, rather than configuration constants.
#let SIZE = (width: 32mm, height: 22mm)
#for style in ("dotted", "solid", "dashed") {
  let settings = (..config.WRITING, pattern: "lines", spacing: 7mm, style: style, color: 180, thickness: 0.8pt)
  let pattern = writing-pattern(SIZE, settings)
  let strokes = descendants(pattern, line)
  assert.eq(strokes.len(), 4)
  assert.eq(descendants(pattern, place).map(it => it.dy), (0mm, 7mm, 14mm, 21mm))
  for stroke in strokes {
    assert.eq(stroke.length, SIZE.width)
    assert.eq(stroke.stroke.paint, luma(180))
    assert.eq(stroke.stroke.thickness, 0.8pt)
    assert.eq(stroke.stroke.dash, line(stroke: (dash: style)).stroke.dash)
  }
  assert.eq(descendants(pattern, rect).len(), 0)
}

#for (spacing, width, height) in ((5mm, 31mm, 21mm), (6mm, 31mm, 19mm)) {
  let pattern = writing-pattern(SIZE, (..config.WRITING, pattern: "grid", spacing: spacing))
  let shapes = descendants(pattern, rect)
  assert.eq(shapes.len(), 1)
  assert.eq(type(shapes.first().fill), tiling)
  assert.eq(shapes.first().width, width)
  assert.eq(shapes.first().height, height)
  assert.eq(descendants(pattern, align).first().alignment, center + top)
}

// Whole cells must still fit when the available area divides exactly.
#let BOUNDED = writing-pattern((width: 30mm, height: 24mm), (..config.WRITING, pattern: "grid", spacing: 6mm))
#assert.eq(descendants(BOUNDED, rect).first().width, 30mm)
#assert.eq(descendants(BOUNDED, rect).first().height, 24mm)
#assert.eq(writing-pattern(SIZE, (..config.WRITING, pattern: "none")), none)

#for rows in (3, 7, 13) {
  let pattern = writing-pattern((width: 148mm, height: rows * 7mm), (..config.WRITING, pattern: "lines", spacing: 7mm))
  assert.eq(descendants(pattern, line).len(), rows + 1, message: "Include the last boundary line in a whole-row area")
}

// Explicit Day row counts keep boundary lines despite fractional layout rounding.
#let FIXED_ROWS = writing-pattern((width: 148mm, height: 48.99mm), (..config.WRITING, pattern: "lines", spacing: 7mm), rows: 7)
#assert.eq(descendants(FIXED_ROWS, line).len(), 8)
#assert.eq(descendants(FIXED_ROWS, place).last().dy, 48.99mm)

#for pattern in ("lines", "grid", "none") {
  for checkboxes in (false, true) {
    let settings = (..config.daily_planner_sections.first(), lines_count: 3, columns: 2, checkbox_show: checkboxes, writing: (..config.WRITING, pattern: pattern, spacing: 8mm))
    let section = writing-section(settings)
    let areas = descendants(section, block).filter(it => it.at("height", default: auto) != auto)
    assert.eq(areas.len(), 1)
    assert.eq(areas.first().height, 24mm)
    let placements = descendants(areas.first(), place)
    assert.eq(placements.map(it => it.dy), if checkboxes { (2mm, 10mm, 18mm) } else { () })
    assert.eq(descendants(section, rect).len(), if checkboxes { 6 } else { 0 })
  }
}

#for pattern in ("grid", "lines", "none") {
  let notes = daily-notes(year: 2026, month: 9, day: 30, settings: (writing: (..config.WRITING, pattern: pattern)))
  let areas = descendants(notes, block).filter(it => it.at("height", default: auto) != auto)
  assert.eq(areas.len(), 1)
  assert.eq(areas.first().height, config.page.height - 2 * config.page.margin_y - config.header.height)
}

Writing pattern assertions passed.
