#import "../config.typ" as config
#import "../lib/calendar.typ": make-standup-label
#import "../lib/layout.typ": page-layout, page-navigation
#import "../lib/sections.typ": writing-line
#import "calendar.typ": calendar_label

#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let daily-standup(year, month, day) = {
  page-layout(
    year: year,
    month: month,
    day: day,
    label-fn: make-standup-label,
    header-right: page-navigation(year, month, day, "standup", calendar_label),
    main-content: block(
      width: 100%,
      height: config.page.height - 2 * config.page.margin_y - config.header.height,
      grid(
        columns: (1fr,),
        rows: (auto, 1fr),
        row-gutter: config.STANDUP.title_gap,
        text(size: config.STANDUP.title_font_size, weight: "bold")[#config.STANDUP.title],
        layout(size => {
          let intervals = int(calc.floor(size.height / config.STANDUP.lines_height))
          for index in range(0, intervals + 1) {
            place(
              top + left,
              dy: index * config.STANDUP.lines_height,
              writing-line(config.STANDUP),
            )
          }
        }),
      ),
    ),
  )
}
