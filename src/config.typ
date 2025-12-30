// Global configuration with nested structures for logical grouping

#import "lib/options.typ" as options
#import "lib/holidays.typ" as special_dates_lib

// Year for the planner
#let year = int(sys.inputs.at("year", default: "2026"))

// Typography
#let font = "DejaVu Sans Mono"

// Special dates
// Either `false` (disable) or a list of date definitions for the selected country.
// The country is provided by the build script via `--country` (default: usa).
#let special_dates = special_dates_lib.special-dates(year, options.country())

// Calendar rendering configuration
#let calendar = (
  // Weekend inclusion control.
  // Default: weekends are excluded.
  // Set `--input weekends=true` to include Sat/Sun.
  // Note: `calendar.weekends` means "include weekends".
  weekends: options.weekends(),

  // 0..255 gray level, where 0=black and 255=white.
  fade: 200,

  // line thickness for `style=strike`.
  strike_thickness: 0.8pt,

  // 0..255 gray level for `style=strike` (normal cells).
  strike_color: 100,

  // Horizontal gap between months in the year view.
  column_gap: if options.weekends() { 5mm } else { 15mm },

  strings: (
    months_full: ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"),
    months_short: ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"),
    weekdays_full: ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"),
    weekdays_short: ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
    weekday_initials_weekends: ("M", "T", "W", "T", "F", "S", "S"),
  ),
)

// Device Support - Pre-configured for reMarkable devices:
// - reMarkable 1: 158mm × 210mm
// - reMarkable 2: 158mm × 210mm (default)
// - reMarkable Pro: 158mm × 210mm
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

  // Font size for the special-day label shown next to the weekday.
  // Default: 80% of `weekday_font_size`.
  day_label_font_size: 12pt * 60%,

  navigation_font_size: 12pt,

  // Quick jump links row (second header row).
  // Shows upcoming dates as links to their Day pages.
  quick_jump_show: true,

  // Number of upcoming dates to show, starting from tomorrow.
  quick_jump_count: 5,

  // 0..255 gray level for the quick jump link text.
  quick_jump_color: 180,

  // Font size for the quick jump link labels.
  quick_jump_font_size: 12pt * 60%,

  // Horizontal gap between quick jump links.
  quick_jump_gap: 5mm,

  // Fixed height for the quick jump row.
  quick_jump_height: 4mm,

  // Label format for each quick jump date.
  // Supported placeholders: {mon}, {month}, {day}, {dd}, {m}, {mm}, {dow}, {weekday}
  quick_jump_format: "{dow} {day}",

  // When your menu button is at the top-right corner, use 10mm, otherwise 5mm
  menu_margin_left: 10mm,

  // When your menu button is at the top-left corner, use 10mm, otherwise 5mm
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
// - columns: (integer) Number of checkboxes per row when checkboxes are shown (default: 1)
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
    columns: 2,
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