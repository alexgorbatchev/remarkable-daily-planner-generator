#import "config.typ" as config
#import "views/calendar.typ": *
#import "views/daily-planner.typ": *
#import "views/daily-notes.typ": *

#set text(font: config.font)

// First page: Year calendar view
#set page(
  width: config.page.width,
  height: config.page.height,
  margin: (x: config.page.margin_x, y: config.page.margin_y),
)

#block(width: 100%, height: 100%)[
  #align(center + horizon)[
    #year-view(year: config.year, factor: 80%, selected: ())
  ]
]

// Generate daily planner pages for every day of the year
#for month in range(1, 13) [
  #let days_in_month = days-in-month(config.year, month)

  #for day in range(1, days_in_month + 1) [
    #pagebreak()
    #daily-planner(year: config.year, month: month, day: day)
  ]
]

// Generate daily notes pages for every day of the year
#for month in range(1, 13) [
  #let days_in_month = days-in-month(config.year, month)

  #for day in range(1, days_in_month + 1) [
    #pagebreak()
    #daily-notes(year: config.year, month: month, day: day)
  ]
]
