
#import "../config.typ" as config
#import "../lib/layout.typ": page-layout
#import "../lib/navigation.typ": page-navigation
#import "../lib/writing-pattern.typ": writing-pattern
#import "../lib/calendar.typ": *
#import "calendar.typ": calendar_label

// Remove default paragraph spacing  
#set par(leading: 0pt, spacing: 0pt)

// Remove default block spacing
#set block(spacing: 0pt)

// Main daily notes function
#let daily-notes(
  year: int,
  month: int,
  day: int,
  header: config.header,
  settings: config.daily_notes,
) = {
  page-layout(
    year: year, 
    month: month, 
    day: day,
    label-fn: make-notes-label, // Use notes label instead of day label
    settings: header,
    header-content: page-navigation(year, month, day, "notes", calendar_label, settings: header),
    main-content: block(
      width: 100%,
      height: config.page.height - 2 * config.page.margin_y - header.height,
      layout(size => writing-pattern(size, settings.writing)),
    ),
  )
}
