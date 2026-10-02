#import "../src/config.typ" as config
#import "../src/lib/navigation.typ": page-navigation
#import "../src/lib/calendar.typ": get-weekday, get-month, fmt2, make-day-label, make-notes-label, make-standup-label
#import "helpers.typ": descendants, plain
#import "presets.typ": HEADER_BLUE, HEADER_UNDERLINE, HEADER_PLAIN

#let CHECK_NAVIGATION(settings, standup-enabled) = {
  for date in ((2026, 1, 1), (2026, 9, 30), (2026, 12, 31), (2028, 2, 29)) {
    let (year, month, day) = date
    let titles = (day: get-weekday(year, month, day, short: settings.weekday_short), notes: settings.notes_label, standup: settings.standup_label)
    let targets = (day: make-day-label(year, month, day), notes: make-notes-label(year, month, day), standup: make-standup-label(year, month, day))
    let kinds = if standup-enabled { ("day", "notes", "standup") } else { ("day", "notes") }
    for current in kinds {
      let header = page-navigation(year, month, day, current, "calendar-view", settings: settings, standup-enabled: standup-enabled)
      let links = descendants(header, link)
      let expected = ()
      for kind in settings.navigation_order {
        if kind == "date" {
          if settings.year_link and settings.date_order.any(it => it == "year") { expected.push(label("calendar-view")) }
        } else if kind != "standup" or standup-enabled {
          expected.push(label(targets.at(kind)))
        }
      }
      assert.eq(links.map(it => it.dest), expected, message: "Navigation links must follow the configured order, availability, and year-link toggle")
      for it in links {
        if it.dest == label("calendar-view") { assert.eq(plain(it.body), str(year)) }
      }
      for kind in kinds {
        let tabs = links.filter(it => it.dest == label(targets.at(kind)))
        assert.eq(tabs.len(), if settings.navigation_order.any(it => it == kind) { 1 } else { 0 })
        if tabs.len() > 0 { assert.eq(plain(tabs.first().body), titles.at(kind)) }
      }
      let visible = settings.navigation_order.any(it => it == current)
      let badges = descendants(header, box).filter(it => it.at("fill", default: none) != none)
      assert.eq(badges.len(), if visible and settings.active_style == "box" { 1 } else { 0 })
      if badges.len() > 0 {
        assert.eq(badges.first().fill, settings.active_box_color)
        assert.eq(badges.first().inset, settings.active_padding)
        assert.eq(plain(badges.first().body), titles.at(current))
      }
      let underlines = descendants(header, underline)
      assert.eq(underlines.len(), if visible and settings.active_style == "underline" { 1 } else { 0 })
      if underlines.len() > 0 { assert.eq(plain(underlines.first().body), titles.at(current)) }
      let active_links = links.filter(it => it.dest == label(targets.at(current)))
      if active_links.len() > 0 { assert.eq(descendants(active_links.first().body, box).first().inset, settings.active_padding) }
      if settings.navigation_order.len() > 0 { assert(descendants(header, align).any(it => it.alignment == settings.navigation_align + top)) }
      let show_standup = settings.navigation_order.any(it => it == "standup") and (standup-enabled or settings.show_disabled_standup)
      assert.eq(descendants(header, text).filter(it => it.text == settings.standup_label).len(), if show_standup { 1 } else { 0 })
      if settings.navigation_order.any(it => it == "date") {
        let month_name = get-month(month, short: settings.month_short)
        let day_number = if settings.day_zero_pad { fmt2(day) } else { str(day) }
        let values = (year: str(year), month: month_name, day: day_number)
        let expected_date = settings.date_order.map(it => values.at(it)).join(settings.date_separator)
        assert(plain(header).replace(" ", "").contains(expected_date.replace(" ", "")))
      }
    }
  }
}

#for settings in (config.header, HEADER_BLUE, HEADER_UNDERLINE, HEADER_PLAIN, (..config.header, show_disabled_standup: false), (..config.header, navigation_order: ())) {
  CHECK_NAVIGATION(settings, false)
  CHECK_NAVIGATION(settings, true)
}

// A reordered, fully formatted header must place complete labels in that order.
#let ORDER_SETTINGS = (..HEADER_UNDERLINE, date_order: ("day", "month", "year"), date_separator: "|")
#let ORDER_PAGE = page-navigation(2026, 9, 30, "notes", "calendar-view", settings: ORDER_SETTINGS, standup-enabled: true)
#assert.eq(plain(ORDER_PAGE).replace(" ", ""), ("Memo30|" + get-month(9) + "|2026" + get-weekday(2026, 9, 30) + "Sync").replace(" ", ""))

Navigation assertions passed.

#include "date-navigator.typ"
#include "standup.typ"
#include "writing-pattern.typ"
