#import "../src/config.typ" as config
#import "../src/lib/layout.typ": page-layout
#import "../src/lib/calendar.typ": make-day-label, make-notes-label, make-standup-label, get-month, get-weekday, fmt2
#import "helpers.typ": descendants, plain

// Independent oracle: enumerate the year, then select included dates by ordinal.
#let EXPECTED_DATES(year, month, day, settings, weekends) = {
  if not settings.quick_jump_show { return () }
  let current = datetime(year: year, month: month, day: day)
  let first = datetime(year: year, month: 1, day: 1)
  let total = datetime(year: year, month: 12, day: 31).ordinal()
  let included = range(total).map(offset => first + duration(days: offset))
    .filter(date => weekends or date.weekday() <= 5)
  let prior = included.filter(date => date.ordinal() < current.ordinal())
  let future = included.filter(date => date.ordinal() > current.ordinal())
  let result = if settings.quick_jump_previous and prior.len() > 0 { (prior.last(),) } else { () }
  result + future.slice(0, calc.min(settings.quick_jump_count, future.len()))
}

#let CHECK_PICKER(date, settings, weekends, label-fn) = {
  let (year, month, day) = date
  let page = page-layout(
    year: year, month: month, day: day, label-fn: label-fn,
    header-content: [], main-content: [], settings: settings, weekends: weekends,
  )
  let destination = if settings.quick_jump_same_view { label-fn } else { make-day-label }
  let expected = EXPECTED_DATES(year, month, day, settings, weekends)
    .map(date => label(destination(date.year(), date.month(), date.day())))
  assert.eq(descendants(page, link).map(it => it.dest), expected, message: "Date picker must honor count, previous-date toggle, weekend filter, year bounds, and destination view")
  assert(descendants(page, align).any(it => it.alignment == settings.quick_jump_align + top))
}

#let PICKER_CASES = ((2026, 1, 1), (2026, 1, 30), (2028, 2, 28), (2028, 3, 1), (2026, 12, 31), (2027, 1, 4))
#let PICKER_LABELS = (make-day-label, make-notes-label, make-standup-label)
#for date in PICKER_CASES {
  for label-fn in PICKER_LABELS { CHECK_PICKER(date, config.header, config.calendar.weekends, label-fn) }
  for weekends in (false, true) {
    for count in (0, 1, 3, 8) {
      for previous in (false, true) {
        for same-view in (false, true) {
          let settings = (..config.header, quick_jump_show: true, quick_jump_count: count, quick_jump_previous: previous, quick_jump_same_view: same-view)
          for label-fn in PICKER_LABELS { CHECK_PICKER(date, settings, weekends, label-fn) }
        }
      }
    }
  }
  CHECK_PICKER(date, (..config.header, quick_jump_show: false), true, make-notes-label)
}

// Every supported placeholder must use the configured format, including localization.
#let FORMAT_SETTINGS = (..config.header, quick_jump_show: true, quick_jump_previous: false, quick_jump_count: 1, quick_jump_format: "{mon}|{month}|{day}|{dd}|{m}|{mm}|{dow}|{weekday}")
#let FORMAT_PAGE = page-layout(year: 2026, month: 1, day: 30, header-content: [], main-content: [], settings: FORMAT_SETTINGS, weekends: false)
#let FORMAT_EXPECTED = (get-month(2, short: true), get-month(2), "2", fmt2(2), "2", fmt2(2), get-weekday(2026, 2, 2, short: true), get-weekday(2026, 2, 2)).join("|")
#assert.eq(plain(FORMAT_PAGE), FORMAT_EXPECTED)

Date navigator assertions passed.
