#import "../config.typ" as config
#import "calendar.typ": days-in-month, monday-index, get-month, get-weekday, fmt2, make-day-label
#import "link.typ": styled_link

#let next-day(year, month, day) = {
  if day < days-in-month(year, month) {
    (year: year, month: month, day: day + 1)
  } else if month < 12 {
    (year: year, month: month + 1, day: 1)
  } else {
    (year: year + 1, month: 1, day: 1)
  }
}

#let quick-jump-label(year, month, day, settings: config.header) = {
  let out = settings.quick_jump_format
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

#let quick-jump-row(year, month, day, label-fn, settings: config.header, weekends: config.calendar.weekends) = {
  if not settings.quick_jump_show { return none }
  let count = settings.quick_jump_count
  assert(count >= 0, message: "quick_jump_count must be nonnegative")
  let destination = if settings.quick_jump_same_view { label-fn } else { make-day-label }
  let date-cell(year, month, day) = {
    let label_text = quick-jump-label(year, month, day, settings: settings)
    let target = label(destination(year, month, day))
    grid.cell(align: left)[
      #set text(size: settings.quick_jump_font_size, fill: luma(settings.quick_jump_color))
      #styled_link(target, [#label_text], padding: settings.quick_jump_padding)
    ]
  }
  let cells = ()
  if settings.quick_jump_previous {
    let previous = datetime(year: year, month: month, day: day) - duration(days: 1)
    while previous.year() == year {
      if weekends or previous.weekday() <= 5 {
        cells.push(date-cell(previous.year(), previous.month(), previous.day()))
        break
      }
      previous -= duration(days: 1)
    }
  }
  let previous_count = cells.len()
  let cur = (year: year, month: month, day: day)
  while cells.len() < count + previous_count {
    cur = next-day(cur.year, cur.month, cur.day)
    if cur.year != year { break }
    if not weekends and monday-index(cur.year, cur.month, cur.day) >= 5 { continue }
    cells.push(date-cell(cur.year, cur.month, cur.day))
  }
  if cells.len() == 0 { return none }
  grid(
    columns: cells.len(), stroke: none, inset: 0pt, align: left,
    column-gutter: settings.quick_jump_gap, row-gutter: 0mm, ..cells,
  )
}
