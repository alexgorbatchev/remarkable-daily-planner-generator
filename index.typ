// Import calendar functions
#import "calendar.typ": *

// Import day planner functions  
#import "day.typ": *

#set text(font: "DejaVu Sans Mono")

// Global constants
#let YEAR = 2025

// First page: Year calendar view
#set page(
  width: 158mm,
  height: 210mm,
  margin: (x: 0mm, y: 0mm),
)

#block(width: 100%, height: 100%)[
  #align(center + horizon)[
    #year-view(year: YEAR, factor: 80%, selected: ())
  ]
]

// Set page format for daily planners
#set page(
  width: 158mm,
  height: 210mm,
  margin: (x: 6mm, y: 6mm),
)

// Generate daily planner pages for every day of the year
#for month in range(1, 13) [
  #let days_in_month = days-in-month(YEAR, month)
  
  #for day in range(1, days_in_month + 1) [
    #pagebreak()
    #daily-planner(year: YEAR, month: month, day: day)
  ]
]