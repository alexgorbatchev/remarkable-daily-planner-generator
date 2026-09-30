#import "../config.typ" as config
#import "../lib/calendar.typ": make-standup-label
#import "../lib/layout.typ": page-layout
#import "../lib/navigation.typ": page-navigation
#import "../lib/sections.typ": writing-line
#import "calendar.typ": calendar_label

#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let daily-standup(year, month, day, header: config.header, settings: config.STANDUP) = {
  let lines = layout(size => {
    let intervals = int(calc.floor(size.height / settings.lines_height))
    for index in range(0, intervals + 1) {
      place(top + left, dy: index * settings.lines_height, writing-line(settings))
    }
  })
  let body = if settings.title_show {
    grid(
      columns: (1fr,), rows: (auto, 1fr), row-gutter: settings.title_gap,
      text(size: settings.title_font_size, weight: "bold")[#settings.title],
      lines,
    )
  } else { lines }
  page-layout(
    year: year,
    month: month,
    day: day,
    label-fn: make-standup-label,
    settings: header,
    header-content: page-navigation(year, month, day, "standup", calendar_label, settings: header),
    main-content: block(
      width: 100%,
      height: config.page.height - 2 * config.page.margin_y - header.height,
      body,
    ),
  )
}
