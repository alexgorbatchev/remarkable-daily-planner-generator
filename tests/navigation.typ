#import "../src/config.typ" as config
#import "../src/lib/layout.typ": page-navigation, page-layout
#import "../src/lib/calendar.typ": get-weekday, make-day-label, make-notes-label, make-standup-label
#import "../src/views/daily-standup.typ": daily-standup

// Inspect generated content, including nested grid cells and styled links.
#let descendants(value, element) = {
  let matches = ()
  if type(value) == content {
    if value.func() == element { matches.push(value) }
    for field in value.fields().values() {
      matches += descendants(field, element)
    }
  } else if type(value) == array {
    for item in value { matches += descendants(item, element) }
  }
  matches
}

#let plain(value) = descendants(value, text).map(it => it.text).join("")

#for date in ((2026, 1, 1), (2026, 9, 30), (2026, 12, 31), (2028, 2, 29)) {
  let (year, month, day) = date
  let weekday = get-weekday(year, month, day, short: true)
  let destinations = (
    (kind: "day", title: weekday, target: make-day-label(year, month, day)),
    (kind: "notes", title: "Notes", target: make-notes-label(year, month, day)),
  )
  if config.STANDUP_ENABLED {
    destinations.push((kind: "standup", title: "Standup", target: make-standup-label(year, month, day)))
  }
  for active in destinations {
    let header = page-navigation(year, month, day, active.kind, "calendar-view")
    let badges = descendants(header, box).filter(it => it.at("fill", default: none) == black)
    assert.eq(badges.len(), 1, message: "Exactly one active tab must have a black background")
    assert.eq(plain(badges.first().body), active.title)
    assert.eq(descendants(header, underline).len(), 0)
    assert.eq(badges.first().inset, 4pt)

    let links = descendants(header, link)
    let year_links = links.filter(it => plain(it.body) == str(year))
    assert.eq(year_links.len(), 1)
    assert.eq(year_links.first().dest, label("calendar-view"))
    let calendar_links = links.filter(it => it.dest == label("calendar-view"))
    assert.eq(calendar_links.len(), 1, message: "Only YYYY may link to the annual calendar")
    assert.eq(plain(calendar_links.first().body), str(year))
    assert.eq(links.len(), destinations.len() + 1, message: "Mon DD must remain plain text")
    for destination in destinations {
      let tabs = links.filter(it => plain(it.body) == destination.title)
      assert.eq(tabs.len(), 1, message: "Every generated page must have a same-date tab")
      assert.eq(tabs.first().dest, label(destination.target))
    }
    assert(plain(header).contains("Notes"))
    assert(plain(header).contains("Standup"))
    if not config.STANDUP_ENABLED {
      assert.eq(links.filter(it => plain(it.body) == "Standup").len(), 0)
    }
    let month_name = config.calendar.strings.months_short.at(month - 1)
    let day_number = if day < 10 { "0" + str(day) } else { str(day) }
    assert(plain(header).starts-with(str(year) + month_name + day_number + weekday))
  }
  let page = page-layout(year: year, month: month, day: day, header-content: [], main-content: [])
  assert(
    descendants(page, align).any(it => it.alignment == left + top),
    message: "Upcoming-date picker must align to the left at the top of its existing row",
  )
}

// Exercise the picker through page-layout so the page's label helper is forwarded.
#let PICKER_CASES = (
  (
    date: (2026, 1, 30),
    previous: ((2026, 1, 29),),
    upcoming: if config.calendar.weekends {
      ((2026, 1, 31), (2026, 2, 1), (2026, 2, 2), (2026, 2, 3), (2026, 2, 4))
    } else {
      ((2026, 2, 2), (2026, 2, 3), (2026, 2, 4), (2026, 2, 5), (2026, 2, 6))
    },
  ),
  (
    date: (2028, 2, 28),
    previous: if config.calendar.weekends { ((2028, 2, 27),) } else { ((2028, 2, 25),) },
    upcoming: if config.calendar.weekends {
      ((2028, 2, 29), (2028, 3, 1), (2028, 3, 2), (2028, 3, 3), (2028, 3, 4))
    } else {
      ((2028, 2, 29), (2028, 3, 1), (2028, 3, 2), (2028, 3, 3), (2028, 3, 6))
    },
  ),
  (
    date: (2028, 3, 1),
    previous: ((2028, 2, 29),),
    upcoming: if config.calendar.weekends {
      ((2028, 3, 2), (2028, 3, 3), (2028, 3, 4), (2028, 3, 5), (2028, 3, 6))
    } else {
      ((2028, 3, 2), (2028, 3, 3), (2028, 3, 6), (2028, 3, 7), (2028, 3, 8))
    },
  ),
  (
    date: (2026, 1, 1), previous: (),
    upcoming: if config.calendar.weekends {
      ((2026, 1, 2), (2026, 1, 3), (2026, 1, 4), (2026, 1, 5), (2026, 1, 6))
    } else {
      ((2026, 1, 2), (2026, 1, 5), (2026, 1, 6), (2026, 1, 7), (2026, 1, 8))
    },
  ),
  (date: (2026, 12, 30), previous: ((2026, 12, 29),), upcoming: ((2026, 12, 31),)),
  (date: (2026, 12, 31), previous: ((2026, 12, 30),), upcoming: ()),
)
#let PICKER_LABELS = if config.STANDUP_ENABLED {
  (make-day-label, make-notes-label, make-standup-label)
} else {
  (make-day-label, make-notes-label)
}
#for case in PICKER_CASES {
  let (year, month, day) = case.date
  for label-fn in PICKER_LABELS {
    let page = page-layout(
      year: year, month: month, day: day,
      label-fn: label-fn, header-content: [], main-content: [],
    )
    let expected = (case.previous + case.upcoming).map(date => {
      let (year, month, day) = date
      label(label-fn(year, month, day))
    })
    assert.eq(
      descendants(page, link).map(it => it.dest), expected,
      message: "Date links must start with the previous included date and stay in the current page type",
    )
  }
}

#if config.STANDUP_ENABLED {
  for date in ((2026, 1, 1), (2026, 9, 30), (2026, 12, 31)) {
    let (year, month, day) = date
    let page = daily-standup(year, month, day)
    assert.eq(
      descendants(page, text).filter(it => it.text == "Standup").len(), 1,
      message: "Standup pages must show only the navigation tab, with no body heading",
    )
  }
}

Navigation assertions passed.
