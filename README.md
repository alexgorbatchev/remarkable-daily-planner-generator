# reMarkable Daily Planner Generator

[![Typst](https://img.shields.io/badge/Powered%20By-Typst-blue.svg)](https://typst.app/)

A customizable daily planner system designed specifically for reMarkable tablet, however could very easily be adopted for any other screen size. In its default form it uses monospace font because I'm a software engineer. 

## Overview
This planner was designed by and for software engineering professionals who need a structured approach to managing their daily technical work. It combines traditional planning concepts with the unique needs of software development workflows.

## Structure
The planner generates a PDF with three main components:

Pages are grouped to make day-to-day navigation easy: all Daily Planner pages are generated as one chronological block (so you can flip back/forward between days), followed by all Daily Notes pages as a separate chronological block.

### 1. Annual Calendar View (1 page)
- Year overview with navigation to any day
- Quick visual reference for planning sprints and releases
- By default, weekends (Sat/Sun) are excluded from the calendar (use `--weekends=true` to include them)

### 2. Daily Planner Pages
Structured for engineering workflows:

- Top Priority: For critical tasks that must be completed
- Primary: Primary tasks for the day, typically work related 
- Secondary: Other tasks, typically personal

Each page includes:
- Date and week number for sprint planning
- Navigation links to corresponding notes and calendar
- Configurable line spacing for different writing preferences

Special dates (from CSV) can also be visually marked in the calendar view and shown in the daily header (e.g. `Friday New Year's Day`).

### 3. Daily Notes Pages
Meetings notes, etc.

## Download

Pre-built PDF planners are available for direct download:

<!-- generated -->
- **[2026, USA, No weekends](build/planner-no-weekends-usa-2026.pdf)**
- **[2026, USA, Weekends](build/planner-weekends-usa-2026.pdf)**
- **[2026, Canada Ontario, No weekends](build/planner-no-weekends-canada-ontario-2026.pdf)**
- **[2026, Canada Ontario, Weekends](build/planner-weekends-canada-ontario-2026.pdf)**
<!-- /generated -->

## Preview

### Calendar view, no weekends
![Calendar View / No Weekends](preview/calendar-view--no-weekends.png)

### Calendar view, weekends
![Calendar View / Weekends](preview/calendar-view--weekends.png)

### Day view
![Day View](preview/day-view.png)

### Day notes view
![Day Notes View](preview/notes-view.png)

### On device
![Device Calendar View](preview/photo-1.png)
![Device Day View](preview/photo-2.png)
![Device Notes View](preview/photo-3.png)

## Configuration
All aspects of the planner are configurable through `config.typ`:

```typst
// Inputs and helpers
#import "lib/options.typ" as options
#import "lib/holidays.typ" as special_dates_lib

// Year for the planner (passed via `--input year=...`)
#let year = int(sys.inputs.at("year", default: "2025"))

// Weekends are excluded by default.
// Set `--input weekends=true` (or use `--weekends=true` in scripts) to include weekends.
// This affects both the daily pages and the calendar view.

// Typography
#let font = "DejaVu Sans Mono"

// Special dates
// Set by build scripts via `--country` (default: usa). Use `--country=none` to disable.
// Special date definitions are read from `dates-YYYY-COUNTRY.csv` in the repo root.
// CSV format: date,style,label (e.g. 2026-01-01,fade,New Year's Day)
// Supported styles: strike, fade

#let special_dates = special_dates_lib.special-dates(year, options.country())

// Calendar rendering configuration
#let calendar = (
  // Note: calendar.weekends means "include weekends".
  weekends: options.weekends(),
  // 0..255 gray level, where 0=black and 255=white.
  fade: 200,
  // line thickness for `style=strike`.
  strike_thickness: 0.8pt,
  // 0..255 gray level for `style=strike` (normal cells).
  strike_color: 100,

  // Horizontal gap between months in the year view.
  column_gap: if options.weekends() { 5mm } else { 15mm },
)

// Device Support - Pre-configured for reMarkable devices:
// - reMarkable 1: 158mm × 210mm
// - reMarkable 2: 158mm × 210mm (default)
// - reMarkable Pro: 158mm × 210mm

// Page layout (optimized for reMarkable 2)
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
  day_label_font_size: 12pt * 60%,
  navigation_font_size: 12pt,

  // Quick jump links (shown above the weekday in the header).
  // Shows upcoming dates as links to their Day pages.
  quick_jump_show: true,
  quick_jump_count: 5,
  quick_jump_color: 180, // 0..255 gray level
  quick_jump_font_size: 12pt * 60%,
  quick_jump_gap: 5mm,
  quick_jump_height: 4mm,
  // Supported placeholders: {mon}, {month}, {day}, {dd}, {m}, {mm}, {dow}, {weekday}
  quick_jump_format: "{dow} {day}",

  // When your menu button is at the top-right corner, use 10mm, otherwise 5mm
  menu_margin_left: 10mm,
  // When your menu button is at the top-left corner, use 10mm, otherwise 5mm
  menu_margin_right: 5mm
)

// Line styling
#let lines_color = 100  // Gray level: 0=black, 255=white

// Daily planner sections (fully customizable)
#let daily_planner_sections = (
  (
    title_label: "Top Priority",
    title_font_size: 11pt,
    lines_count: 3,
    lines_height: 7mm,
    lines_style: "dotted",
    lines_color: lines_color,
    checkbox_show: true,
    // Number of checkboxes per line (default: 1). When >1, checkboxes are
    // evenly spaced across the row and left-aligned within each column.
    columns: 1,
    checkbox_size: 4mm,
    checkbox_color: 200
  ),
  // ... additional sections
)

// Daily notes configuration
#let daily_notes = (
  lines_show: true,
  lines_size: 5mm,
  lines_style: "grid",
  lines_color: lines_color
)
```

## Building

```bash
# Generate the complete planner using the build script.
./build.sh 2026

# Include weekends.
./build.sh --year=2026 --weekends=true

# Select special dates country (default: usa).
./build.sh --year=2026 --country=usa

# Disable special date markings.
./build.sh --year=2026 --country=none

# Open the generated PDF after building.
./build.sh --year=2026 --open

# Watch for changes (auto-regenerate on save).
./build.sh --year=2026 --watch

# Compile directly with Typst.
typst compile --input year=2026 index.typ build/planner-2026.pdf

# Watch directly with Typst.
typst watch --input year=2026 index.typ build/planner-2026.pdf

# Include weekends (direct Typst).
typst compile --input year=2026 --input weekends=true index.typ build/planner-2026.pdf

# Select special dates country (direct Typst).
typst compile --input year=2026 --input country=usa index.typ build/planner-2026.pdf
```

This creates a PDF ready for printing or digital use.

## File Structure

```
├── config.typ              # Global configuration
├── index.typ               # Main coordinator
├── lib/                    # Shared utilities
│   ├── calendar.typ        # Date calculations
│   ├── layout.typ          # Page layout system
│   └── link.typ            # Navigation links
└── views/                  # Page templates
    ├── calendar.typ        # Annual calendar view
    ├── daily-planner.typ   # Daily task planning
    └── daily-notes.typ     # Technical notes with grid
```

## License

MIT

## Contributing

Open a PR.
