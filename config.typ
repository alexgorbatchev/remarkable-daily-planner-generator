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

// Header configuration
#let header = (
  height: 15mm,
  date_font_size: 24pt,
  weekday_font_size: 12pt,
  navigation_font_size: 12pt,

  // when your menu button is at the top-right corner, use 10mm, otherwise 5mm
  menu_margin_left: 10mm,

  // when your menu button is at the top-left corner, use 10mm, otherwise 5mm
  menu_margin_right: 5mm
)

#let lines_color = 100

// Daily planner sections configuration
// Each section is a dictionary that defines a titled area with configurable lines and styling.
// Sections are rendered in order from top to bottom on each daily planner page.
//
// Section properties:
// - title_label: (string) The section heading text displayed above the lines
// - title_font_size: (length) Font size for the section title (e.g. 11pt, 12pt, 14pt)
// - lines_count: (integer) Number of lines to render in this section (1-50)
// - lines_height: (length) Vertical spacing between lines (e.g. 5mm, 7mm, 10mm)
// - lines_style: (string) Line appearance - "solid", "dotted", "dashed", or "none"
// - lines_color: (integer) Gray level for lines, 0=black, 255=white (e.g. 200 for light gray)
// - checkbox_show: (boolean) Whether to show checkboxes at the start of each line (true/false)
// - checkbox_size: (length) Size of checkbox squares when shown (e.g. 3mm, 4mm, 5mm)
// - checkbox_color: (integer) Gray level for checkbox borders, 0=black, 255=white
//
// Example section types:
// - Task lists: checkbox_show: true, lines_style: "dotted"
// - Note areas: checkbox_show: false, lines_style: "solid" 
// - Planning: checkbox_show: true, lines_height: 10mm for more space
#let daily_planner_sections = (
  (
    title_label: "Top Priority",
    title_font_size: 11pt,
    lines_count: 3,
    lines_height: 7mm,
    lines_style: "dotted",
    lines_color: lines_color,
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
    lines_color: lines_color,
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
    lines_color: lines_color,
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
  lines_color: lines_color
)