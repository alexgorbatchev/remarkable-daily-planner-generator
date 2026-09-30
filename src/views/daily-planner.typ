#import "../config.typ" as config
#import "../lib/layout.typ": page-layout
#import "../lib/navigation.typ": page-navigation
#import "../lib/sections.typ": section-with-lines
#import "calendar.typ": calendar_label

#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let daily-planner(year: int, month: int, day: int, header: config.header) = {
  page-layout(
    year: year,
    month: month,
    day: day,
    settings: header,
    header-content: page-navigation(year, month, day, "day", calendar_label, settings: header),
    main-content: [
      #for section in config.daily_planner_sections [
        #section-with-lines(section)
        #v(5mm)
      ]
    ],
  )
}
