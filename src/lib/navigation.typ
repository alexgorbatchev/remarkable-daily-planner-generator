#import "../config.typ" as config
#import "calendar.typ": get-weekday, get-month, fmt2, make-day-label, make-notes-label, make-standup-label
#import "link.typ": styled_link
#import "holidays.typ" as special_dates

#let DATE_HEADER(year, month, day, calendar-target, settings) = {
  let values = (
    year: [#year],
    month: [#get-month(month, short: settings.month_short)],
    day: [#if settings.day_zero_pad { fmt2(day) } else { str(day) }],
  )
  let parts = ()
  for component in settings.date_order {
    assert(component in values, message: "date_order supports year, month, and day")
    assert.eq(settings.date_order.filter(it => it == component).len(), 1, message: "date_order must not repeat components")
    let part = values.at(component)
    if component == "year" and settings.year_link {
      part = styled_link(label(calendar-target), part, padding: settings.year_link_padding)
    }
    parts.push(part)
  }
  text(size: settings.date_font_size, weight: settings.date_weight, parts.join(settings.date_separator, default: []))
}

// Same-date navigation, with the current layout supplied by the default settings.
#let page-navigation(year, month, day, current, calendar-target, settings: config.header, standup-enabled: config.STANDUP_ENABLED) = {
  assert(("box", "underline", "none").any(it => it == settings.active_style), message: "active_style must be box, underline, or none")
  let titles = (
    day: get-weekday(year, month, day, short: settings.weekday_short),
    notes: settings.notes_label,
    standup: settings.standup_label,
  )
  let targets = (day: make-day-label, notes: make-notes-label, standup: make-standup-label)
  let cells = ()
  for kind in settings.navigation_order {
    assert(kind == "date" or kind in titles, message: "navigation_order supports date, day, notes, and standup")
    assert.eq(settings.navigation_order.filter(it => it == kind).len(), 1, message: "navigation_order must not repeat components")
    if kind == "date" {
      cells.push(DATE_HEADER(year, month, day, calendar-target, settings))
      continue
    }
    if kind == "standup" and not standup-enabled and not settings.show_disabled_standup { continue }
    let active = kind == current
    let color = settings.inactive_text_color
    if active {
      color = if settings.active_text_color == auto {
        if settings.active_style == "box" { white } else { settings.inactive_text_color }
      } else { settings.active_text_color }
    }
    let title = text(
      fill: color,
      bottom-edge: if active and settings.active_style == "box" { "bounds" } else { "baseline" },
      [#titles.at(kind)],
    )
    if active and settings.active_style == "underline" {
      title = underline(
        stroke: (paint: color, thickness: settings.active_underline_thickness),
        offset: settings.active_underline_offset,
        evade: settings.active_underline_evade,
        title,
      )
    }
    let tab = title
    if kind != "standup" or standup-enabled {
      let target = targets.at(kind)
      tab = styled_link(
        label(target(year, month, day)), title,
        padding: if active { settings.active_padding } else { settings.inactive_padding },
        fill: if active and settings.active_style == "box" { settings.active_box_color } else { none },
      )
    }
    if kind == "day" {
      tab = text(size: settings.weekday_font_size, tab)
      let special_date = special_dates.special-date-entry(config.special_dates, month, day)
      if special_date != none and special_date.label != none and special_date.label != "" {
        tab = grid(
          columns: (auto,), row-gutter: settings.day_label_gap,
          tab, text(size: settings.day_label_font_size)[#special_date.label],
        )
      }
    }
    cells.push(tab)
  }
  if cells.len() == 0 { return none }
  text(size: settings.navigation_font_size,
    align(settings.navigation_align + top,
      grid(columns: (auto,) * cells.len(), align: left + top, column-gutter: settings.navigation_gap, ..cells),
    ),
  )
}
