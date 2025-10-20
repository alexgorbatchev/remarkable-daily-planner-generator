

// Remove default paragraph spacing
#set par(leading: 0pt, spacing: 0pt)

// Remove default block spacing
#set block(spacing: 0pt)

// Global font size variables
#let FONT_SIZE_LARGE = 24pt
#let FONT_SIZE_MEDIUM = 12pt
#let FONT_SIZE_SMALL = 11pt

// Helper function to get day of year for week calculation
#let day-of-year(year, month, day) = {
  let days_in_months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  if ((calc.rem(year, 4) == 0 and calc.rem(year, 100) != 0) or calc.rem(year, 400) == 0) {
    days_in_months.at(1) = 29
  }

  let total = day
  for i in range(0, month - 1) {
    total += days_in_months.at(i)
  }
  total
}

// Helper function to get ISO week number
#let get-week-number(year, month, day) = {
  let doy = day-of-year(year, month, day)

  // Get January 1st day of week (0 = Monday, 6 = Sunday)
  let jan1_dow = {
    let m = 13 // January of previous year in Zeller's
    let y = year - 1
    let K = calc.rem(y, 100)
    let J = int((y - K) / 100)
    let h = calc.rem(1 + int((13 * 14) / 5) + K + int(K / 4) + int(J / 4) - 2 * J, 7)
    calc.rem(h + 5, 7) // Convert to Monday=0 system
  }

  // Calculate week number
  let week = int((doy + jan1_dow - 1) / 7) + 1

  // Handle edge cases for ISO week numbering
  if week == 0 {
    53 // Week belongs to previous year
  } else if week == 53 {
    // Check if this week belongs to next year
    let dec31_doy = if ((calc.rem(year, 4) == 0 and calc.rem(year, 100) != 0) or calc.rem(year, 400) == 0) {
      366
    } else { 365 }
    let dec31_dow = calc.rem(jan1_dow + dec31_doy - 1, 7)
    if dec31_dow < 4 { 1 } else { 53 }
  } else {
    week
  }
}

// Helper function to get weekday name using Zeller's congruence
#let get-weekday(year, month, day, short: false) = {
  let day_names_full = ("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
  let day_names_short = ("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri")

  // Zeller's congruence for Gregorian calendar
  let m = if month <= 2 { month + 12 } else { month }
  let y = if month <= 2 { year - 1 } else { year }
  let K = calc.rem(y, 100)
  let J = int((y - K) / 100)

  let h = calc.rem(
    day + int((13 * (m + 1)) / 5) + K + int(K / 4) + int(J / 4) - 2 * J,
    7,
  )

  if short {
    day_names_short.at(h)
  } else {
    day_names_full.at(h)
  }
}

// Helper function to get month name
#let get-month(month, short: false) = {
  let months_full = ("January", "February", "March", "April", "May", "June", 
                     "July", "August", "September", "October", "November", "December")
  let months_short = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  
  if short {
    months_short.at(month - 1)
  } else {
    months_full.at(month - 1)
  }
}

// Function to create a checkbox
#let checkbox() = {
  rect(width: 4mm, height: 4mm, stroke: 0.5pt, fill: none)
}

// Function to create a line for writing
#let writing-line(width: 100%) = {
  line(length: width, stroke: (paint: gray, thickness: 0.4pt))
}

// Function to create the header section
#let day-header(year: int, month: int, day: int) = {
  let day_name = get-weekday(year, month, day, short: false)
  let month_abbrev = get-month(month, short: true)
  let week_num = get-week-number(year, month, day)

  block(below: 5mm)[
    #grid(
      columns: (1fr, auto),
      align: (left, right + bottom),

      // Left side: Date and day name
      [
        #grid(
          columns: (auto, auto),
          align: (left + bottom, left + bottom),  // Use bottom alignment for baseline
          column-gutter: 5mm,
          [
            #text(size: FONT_SIZE_LARGE, weight: "bold")[#month_abbrev #day]
          ],
          [
            #text(size: FONT_SIZE_MEDIUM)[#day_name]
          ],
        )
      ],

      // Right side: Year and week
      [
        #grid(
          columns: (auto, auto),
          align: (left + bottom, left + bottom),
          column-gutter: 5mm,
          [
            #text(size: FONT_SIZE_MEDIUM)[Week #week_num]
          ],
          [
            #text(size: FONT_SIZE_MEDIUM)[#year]
          ],
        )
      ],
    )
  ]
}

// Function to create a section with lines
#let section-with-lines(title: str, num_lines: int, with_checkboxes: false) = {
  // Section header with underline
  block(spacing: 0pt)[
    #text(size: FONT_SIZE_SMALL, weight: "bold")[#title]
  ]
  v(2mm)
  writing-line()

  // Lines with optional checkboxes
  for i in range(num_lines) {
    if with_checkboxes {
      v(2mm)
      block(spacing: 0mm)[#checkbox()]
      v(2mm)
      block(spacing: 0mm)[#writing-line()]
    } else {
      if i < num_lines - 1 { v(7mm) }
      block(spacing: 0mm)[#writing-line()]
    }
  }
}

// Main daily planner function
#let daily-planner(
  year: int,
  month: int,
  day: int,
  priority_lines: 3,
  todo_lines: 11,
  maybe_lines: 5,
) = {
  // Header
  day-header(year: year, month: month, day: day)

  v(2mm)

  // Top priority section
  section-with-lines(title: "Top priority", num_lines: priority_lines, with_checkboxes: false)

  v(10mm)

  // To-dos section
  section-with-lines(title: "Work", num_lines: todo_lines, with_checkboxes: true)

  v(10mm)

  // Maybe/someday section
  section-with-lines(title: "Other", num_lines: maybe_lines, with_checkboxes: true)
}


