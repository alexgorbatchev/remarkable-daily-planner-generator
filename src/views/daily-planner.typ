#import "../config.typ" as config
#import "../lib/layout.typ": page-layout, page-navigation
#import "../lib/sections.typ": section-with-lines
#import "calendar.typ": calendar_label

#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let daily-planner(year: int, month: int, day: int) = {
  page-layout(
    year: year,
    month: month,
    day: day,
    header-content: page-navigation(year, month, day, "day", calendar_label),
    main-content: [
      #for section in config.daily_planner_sections [
        #section-with-lines(section)
        #v(5mm)
      ]
    ],
  )
}
