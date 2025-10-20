// Global configuration with nested structures for logical grouping

// Year for the planner
#let year = 2025

// Typography
#let font = "DejaVu Sans Mono"

// Page layout
#let page = (
  width: 158mm,
  height: 210mm,
  margin_x: 5mm,
  margin_y: 5mm
)

// Navigation
#let calendar_label = "calendar-view"

// Header configuration
#let header = (
  height: 15mm,
  date_font_size: 24pt,
  weekday_font_size: 12pt,
  navigation_font_size: 12pt
)

// Daily planner sections configuration
#let daily_planner_sections = (
  (
    title_label: "Top Priority",
    title_font_size: 11pt,
    lines_count: 3,
    lines_height: 7mm,
    lines_style: "dotted",
    lines_color: 200,
    checkbox_show: true,
    checkbox_size: 4mm,
    checkbox_color: 200
  ),
  (
    title_label: "Primary",
    title_font_size: 11pt,
    lines_count: 13,
    lines_height: 7mm,
    lines_style: "dotted",
    lines_color: 200,
    checkbox_show: true,
    checkbox_size: 4mm,
    checkbox_color: 200
  ),
  (
    title_label: "Secondary",
    title_font_size: 11pt,
    lines_count: 7,
    lines_height: 7mm,
    lines_style: "dotted",
    lines_color: 200,
    checkbox_show: true,
    checkbox_size: 4mm,
    checkbox_color: 200
  )
)

// Daily notes configuration
#let daily_notes = (
  lines_show: true,
  lines_size: 5mm,
  lines_style: "grid",
  lines_color: 200
)