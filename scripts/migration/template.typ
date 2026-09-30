#import "/src/config.typ" as config
#import "/src/views/calendar.typ": year-view
#import "/src/views/daily-planner.typ": daily-planner
#import "/src/views/daily-notes.typ": daily-notes
#import "/src/views/daily-standup.typ": daily-standup
#import "/src/lib/calendar.typ": days-in-month, monday-index, fmt2

#let MIGRATION = json(sys.inputs.at("migration-settings"))
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
        #{
          let ISO = str(config.year) + "-" + fmt2(month) + "-" + fmt2(day)
          let HEADER = config.header
          if kind == "notes" {
            let overrides = MIGRATION.grid_overrides.filter(it => it.date == ISO)
            if overrides.len() > 0 {
              HEADER = (..HEADER, height: config.page.height - overrides.first().origin_y * 1pt - config.page.margin_y + 0.3mm)
            }
          }
          if kind == "standup" {
            // Full template labels exist for compilation, but only selected dates
            // have Standup pages in the migration output.
            if MIGRATION.standups.len() == 0 or ISO <= MIGRATION.standups.first() {
              HEADER = (..HEADER, quick_jump_previous: false)
            }
          }
          if kind == "day" { daily-planner(year: config.year, month: month, day: day, header: HEADER) }
          else if kind == "notes" { daily-notes(year: config.year, month: month, day: day, header: HEADER) }
          else { daily-standup(config.year, month, day, header: HEADER) }
        }
      ]
    ]
  ]
]
