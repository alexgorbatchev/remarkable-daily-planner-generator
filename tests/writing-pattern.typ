#import "../src/config.typ" as config
#import "../src/lib/writing-pattern.typ": writing-pattern
#import "../src/lib/sections.typ": writing-section, checkbox-row, section-writing-body
#import "../src/views/daily-notes.typ": daily-notes
#import "../src/views/daily-planner.typ": daily-planner
#import "helpers.typ": descendants, plain

// Inspect generated shapes and positions, rather than configuration constants.
#let SIZE = (width: 32mm, height: 22mm)
#let CENTERED_ROW_SETTINGS = (..config.daily_planner_sections.first(), columns: 1, checkbox_size: 4mm, writing: (..config.WRITING, pattern: "grid", spacing: 6mm))
#let CENTERED_ROW = checkbox-row(CENTERED_ROW_SETTINGS, 32mm)
#assert.eq(descendants(CENTERED_ROW, place).len(), 1)
#assert.eq(descendants(CENTERED_ROW, place).first().dx, 1.5mm)

#for (width, expected) in ((32mm, (1.5mm, 13.5mm)), (34mm, (2.5mm, 14.5mm)), (30mm, (1mm, 13mm))) {
  let row = checkbox-row((..CENTERED_ROW_SETTINGS, columns: 2), width)
  assert.eq(descendants(row, place).map(it => it.dx), expected)
  assert.eq(descendants(row, rect).len(), 2)
}

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
  let shapes = descendants(pattern, box)
  assert.eq(shapes.len(), 1)
  assert.eq(shapes.first().width, width)
  assert.eq(shapes.first().height, height)
  assert.eq(descendants(pattern, align).first().alignment, center + top)
  let horizontals = descendants(pattern, place).filter(it => it.body.at("length", default: none) != none)
  assert.eq(horizontals.map(it => it.dy), range(0, int(calc.floor(SIZE.height / spacing)) + 1).map(index => index * spacing))
  let verticals = descendants(pattern, place).filter(it => it.body.at("length", default: none) == none)
  assert.eq(verticals.map(it => it.dx), range(0, int(calc.floor(SIZE.width / spacing)) + 1).map(index => index * spacing))
}

// Whole cells must still fit when the available area divides exactly.
#let BOUNDED = writing-pattern((width: 30mm, height: 24mm), (..config.WRITING, pattern: "grid", spacing: 6mm))
#assert.eq(descendants(BOUNDED, box).first().width, 30mm)
#assert.eq(descendants(BOUNDED, box).first().height, 24mm)
#assert.eq(descendants(BOUNDED, place).filter(it => it.body.at("length", default: none) != none).map(it => it.dy), (0mm, 6mm, 12mm, 18mm, 24mm))
#assert.eq(writing-pattern(SIZE, (..config.WRITING, pattern: "none")), none)

// Grids need every horizontal boundary, including the bottom edge.
// Fixed Day rows must also survive slightly shortened measured layout areas.
#for style in ("solid", "dotted", "dashed") {
  for (rows, spacing) in ((5, 7mm), (18, 7mm), (4, 6mm)) {
    for shortfall in (0mm, 0.01mm) {
      let height = rows * spacing - shortfall
      let settings = (..config.WRITING, pattern: "grid", spacing: spacing, style: style, color: 180, thickness: 0.8pt)
      let background = writing-pattern((width: 148mm, height: height), settings, rows: rows)
      let shape = descendants(background, box).first()
      assert.eq(shape.height, height, message: "Grid must include the final writing row")
      let boundaries = descendants(background, place).filter(it => it.body.at("length", default: none) != none)
      assert.eq(boundaries.len(), rows + 1)
      assert.eq(boundaries.last().dy, height)
      for (index, boundary) in boundaries.enumerate() {
        assert.eq(boundary.dy, calc.min(index * spacing, height))
        assert.eq(boundary.body.length, shape.width)
        assert.eq(boundary.body.stroke.paint, luma(180))
        assert.eq(boundary.body.stroke.thickness, 0.8pt)
        assert.eq(boundary.body.stroke.dash, line(stroke: (dash: style)).stroke.dash)
      }
    }
  }
}

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
    let body = section-writing-body((width: 32mm, height: areas.first().height), settings)
    let placements = descendants(body, place).filter(it => it.body.func() == box)
    let offsets = if pattern == "grid" { (1.7mm, 9.7mm, 17.7mm) } else { (2mm, 10mm, 18mm) }
    assert.eq(placements.len(), if checkboxes { offsets.len() } else { 0 })
    for (placement, offset) in placements.zip(offsets) {
      assert.eq(placement.dy.ratio, 0%)
      assert(calc.abs(placement.dy.length - offset) < 0.0001pt)
    }
    assert.eq(descendants(body, rect).len(), if checkboxes { 6 } else { 0 })
  }
}

#for pattern in ("grid", "lines", "none") {
  let notes = daily-notes(year: 2026, month: 9, day: 30, settings: (writing: (..config.WRITING, pattern: pattern)))
  let areas = descendants(notes, block).filter(it => it.at("height", default: auto) != auto)
  assert.eq(areas.len(), 1)
  assert.eq(areas.first().height, config.page.height - 2 * config.page.margin_y - config.header.height)
}

// Verify Day emits the configured objective sections, in order and at their sizes.
#let DAY = daily-planner(year: 2026, month: 9, day: 30)
#let DAY_AREAS = descendants(DAY, block).filter(it => it.at("height", default: auto) != auto)
#let DAY_TITLES = config.daily_planner_sections.map(it => it.title_label)
#assert.eq(DAY_AREAS.len(), config.daily_planner_sections.len())
#assert.eq(descendants(DAY, block).filter(it => it.at("height", default: auto) == auto).map(it => plain(it.body)).filter(it => it in DAY_TITLES), DAY_TITLES)
#for index in range(DAY_AREAS.len()) {
  let area = DAY_AREAS.at(index)
  let section = config.daily_planner_sections.at(index)
  assert.eq(area.height, section.lines_count * section.writing.spacing)
  let background = writing-pattern((width: config.page.width - 2 * config.page.margin_x, height: area.height), section.writing, rows: section.lines_count)
  if section.writing.pattern == "grid" {
    let boundaries = descendants(background, place).filter(it => it.body.at("length", default: none) != none)
    assert.eq(boundaries.len(), section.lines_count + 1)
    assert.eq(boundaries.last().dy, area.height)
  } else if section.writing.pattern == "lines" {
    assert.eq(descendants(background, line).len(), section.lines_count + 1)
  } else {
    assert.eq(background, none)
  }
}

// Section count remains configurable rather than fixed inside the view.
#let CUSTOM_SECTIONS = range(3).map(index => (..config.daily_planner_sections.first(), title_label: "Custom " + str(index)))
#let CUSTOM_DAY = daily-planner(year: 2026, month: 9, day: 30, sections: CUSTOM_SECTIONS)
#assert.eq(descendants(CUSTOM_DAY, block).filter(it => it.at("height", default: auto) != auto).len(), 3)

Writing pattern assertions passed.
