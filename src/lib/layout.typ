#import "../config.typ" as config
#import "calendar.typ": make-day-label
#import "date-navigator.typ": quick-jump-row

// Shared geometry for the daily navigation and writing area.
#let page-layout(
  year: int, month: int, day: int,
  header-content: content, main-content: content,
  label-fn: make-day-label,
  settings: config.header,
  weekends: config.calendar.weekends,
) = {
  let quick_jump = quick-jump-row(year, month, day, label-fn, settings: settings, weekends: weekends)
  let link_target = label-fn(year, month, day)
  grid(
    rows: (settings.height, 1fr), row-gutter: 0mm,
    align(top)[
      #{
        let header_main = pad(
          left: settings.menu_margin_left - config.page.margin_x,
          right: settings.menu_margin_right - config.page.margin_x,
        )[
          #header-content
        ]
        pad(
          top: settings.top_gap,
          grid(
            columns: (1fr,), rows: (settings.quick_jump_height, auto), row-gutter: 0mm,
            pad(
              left: settings.menu_margin_left - config.page.margin_x,
              right: settings.menu_margin_right - config.page.margin_x,
              align(settings.quick_jump_align + top, quick_jump),
            ),
            header_main,
          ),
        )
      }
      #label(link_target)
    ],
    main-content,
  )
}
