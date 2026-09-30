#import "../src/config.typ" as config
#import "../src/views/calendar.typ": year-view
#import "../src/views/daily-planner.typ": daily-planner
#import "../src/views/daily-notes.typ": daily-notes
#import "../src/views/daily-standup.typ": daily-standup
#import "../src/lib/calendar.typ": days-in-month, monday-index
#import "presets.typ": HEADER_BLUE, HEADER_UNDERLINE, HEADER_PLAIN, STANDUP_TITLED

// Render complete linked planners with nondefault settings, not placeholder targets.
#let PRESET = sys.inputs.at("preset", default: "blue")
#assert(("blue", "underline", "plain").any(it => it == PRESET))
#let HEADER = if PRESET == "blue" { HEADER_BLUE } else if PRESET == "underline" { HEADER_UNDERLINE } else { HEADER_PLAIN }
#let STANDUP = if PRESET == "blue" { STANDUP_TITLED } else { config.STANDUP }
#set text(font: config.font)
#set page(width: config.page.width, height: config.page.height, margin: (x: config.page.margin_x, y: config.page.margin_y))

#block(width: 100%, height: 100%)[
  #align(center + horizon)[#year-view(year: config.year, factor: 80%, selected: ())]
]
#for kind in ("day", "notes", "standup") [
  #for month in range(1, 13) [
    #for day in range(1, days-in-month(config.year, month) + 1) [
      #if config.calendar.weekends or monday-index(config.year, month, day) < 5 [
        #pagebreak()
        #if kind == "day" {
          daily-planner(year: config.year, month: month, day: day, header: HEADER)
        } else if kind == "notes" {
          daily-notes(year: config.year, month: month, day: day, header: HEADER)
        } else {
          daily-standup(config.year, month, day, header: HEADER, settings: STANDUP)
        }
      ]
    ]
  ]
]
