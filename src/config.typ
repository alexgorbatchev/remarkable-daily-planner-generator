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
  height: 15mm + 3pt,
  // Blank space above the navigation row for the top toolbar.
  top_gap: 4mm,
  date_font_size: 12pt,
  weekday_font_size: 12pt,

  // Special-date label beneath the weekday.
  day_label_font_size: 12pt * 60%,
  day_label_gap: 1mm + 2pt,

  navigation_font_size: 12pt,
  navigation_order: ("date", "day", "notes", "standup"),
  navigation_align: left,
  navigation_gap: 4mm,
  notes_label: "Notes",
  standup_label: "Standup",
  show_disabled_standup: true,

  date_order: ("year", "month", "day"),
  date_separator: " ",
  date_weight: "bold",
  month_short: true,
  day_zero_pad: true,
  weekday_short: true,
  year_link: true,
  year_link_padding: 2pt,

  // Active style: "box", "underline", or "none".
  active_style: "box",
  active_box_color: black,
  // auto chooses white for boxes and the inactive text color otherwise.
  active_text_color: auto,
  inactive_text_color: black,
  active_padding: 4pt,
  inactive_padding: 2pt,
  active_underline_thickness: 1pt,
  active_underline_offset: 2pt,
  active_underline_evade: false,

  // Quick jump links row, left-aligned above the main header.
  // Shows the previous included date, then upcoming dates in the current page type.
  quick_jump_show: true,
  quick_jump_previous: true,
  quick_jump_same_view: true,
  quick_jump_align: left,
  quick_jump_padding: 2pt,

  // Number of upcoming dates, excluding the optional previous-date link.
  // Zero permits previous-only navigation; quick_jump_show hides the whole row.
  quick_jump_count: 5,

  // 0..255 gray level for the quick jump link text.
  quick_jump_color: 180,

  // Font size for the quick jump link labels.
  quick_jump_font_size: 12pt * 60%,

  // Horizontal gap between quick jump links.
  quick_jump_gap: 5mm,

  // Fixed height for the quick jump row.
  // Reserve this space even when links are hidden, to clear the top toolbar.
  quick_jump_height: 4mm + 1pt,

  // Label format for each quick jump date.
  // Supported placeholders: {mon}, {month}, {day}, {dd}, {m}, {mm}, {dow}, {weekday}
  quick_jump_format: "{dow} {day}",

  // When your menu button is at the top-right corner, use 10mm, otherwise 5mm
  menu_margin_left: 5mm,

  // When your menu button is at the top-left corner, use 10mm, otherwise 5mm
  menu_margin_right: 5mm
)

#let lines_color = 100

// Shared writing defaults. Override these fields per page or Day section.
// pattern: "lines", "grid", or "none"; spacing: line gap or square cell size.
#let WRITING = (
  pattern: "grid",
  spacing: 7mm,
  style: "dotted",
  color: lines_color,
  thickness: 0.6pt,
)

// Daily planner sections configuration
// Each section defines a titled writing area with an independently configurable pattern.
// Sections are rendered in order from top to bottom on each daily planner page.
//
// Section properties:
// - title_label: (string) The section heading text displayed above the lines
// - title_font_size: (length) Font size for the section title (e.g. 11pt, 12pt, 14pt)
// - lines_count: (integer) Number of writing rows; controls the section height
// - writing: (dictionary) Pattern, spacing, style, color, and thickness from WRITING
// - checkbox_show: (boolean) Whether to show checkboxes at the start of each line (true/false)
// - columns: (integer) Number of checkboxes per row (default: 1); centered in grid cells
// - checkbox_size: (length) Size of checkbox squares when shown (e.g. 3mm, 4mm, 5mm)
// - checkbox_color: (integer) Gray level for checkbox borders, 0=black, 255=white
//
// Example section types:
// - Task lists: checkbox_show: true, writing: WRITING
// - Note areas: checkbox_show: false, writing: (..WRITING, pattern: "grid")
// - Planning: writing: (..WRITING, spacing: 10mm) for more space
#let daily_planner_sections = (
  (
    title_label: "Primary Objectives",
    title_font_size: 11pt,
    columns: 1,
    lines_count: 5,
    writing: WRITING,
    checkbox_show: true,
    checkbox_size: 4mm,
    checkbox_color: 200
  ),
  (
    title_label: "Secondary Objectives",
    title_font_size: 11pt,
    lines_count: 18,
    writing: WRITING,
    checkbox_show: true,
    checkbox_size: 4mm,
    checkbox_color: 200
  )
)

// Daily notes configuration
#let daily_notes = (
  writing: (..WRITING, pattern: "grid", spacing: 5mm, thickness: 1pt),
)

// Standup shares the Notes grid defaults; override writing independently here.
#let STANDUP = (
  enabled: false,
  title_show: false,
  title: "Standup",
  title_font_size: 11pt,
  title_gap: 2mm,
  writing: daily_notes.writing,
)

// Explicit CLI input overrides the configured default.
#let STANDUP_ENABLED = options.input-bool("standup", default: STANDUP.enabled)
