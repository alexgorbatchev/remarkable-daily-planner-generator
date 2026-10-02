#import "../config.typ" as config
#import "../lib/layout.typ": page-layout
#import "../lib/navigation.typ": page-navigation
#import "../lib/sections.typ": writing-section
#import "calendar.typ": calendar_label

#set par(leading: 0pt, spacing: 0pt)
#set block(spacing: 0pt)

#let daily-planner(year: int, month: int, day: int, header: config.header, sections: config.daily_planner_sections) = {
  page-layout(
    year: year,
    month: month,
    day: day,
    settings: header,
    header-content: page-navigation(year, month, day, "day", calendar_label, settings: header),
    main-content: [
      #for section in sections [
        #writing-section(section)
        #v(5mm)
      ]
    ],
  )
}
