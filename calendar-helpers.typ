// Calendar and date calculation helper functions

// Leap year calculation
#let is-leap(y) = (calc.rem(y, 4) == 0 and calc.rem(y, 100) != 0) or calc.rem(y, 400) == 0

// Number of days in a given month
#let days-in-month(y, m) = if m == 2 {
  if is-leap(y) { 29 } else { 28 }
} else if (m == 1) or (m == 3) or (m == 5) or (m == 7) or (m == 8) or (m == 10) or (m == 12) {
  31
} else {
  30
}

// Floor division helper
#let floor-div(a, b) = int((a - calc.rem(a, b)) / b)

// Zeller's congruence (Gregorian calendar)
#let zeller-h(y, m, d) = {
  let mm = if m <= 2 { m + 12 } else { m }
  let yy = if m <= 2 { y - 1 } else { y }
  let K = int(calc.rem(yy, 100))
  let J = floor-div(yy, 100)
  let t1 = d
  let t2 = floor-div(13 * (mm + 1), 5)
  let t3 = K
  let t4 = floor-div(K, 4)
  let t5 = floor-div(J, 4)
  let t6 = 5 * J
  int(calc.rem(t1 + t2 + t3 + t4 + t5 + t6, 7))
}

// Convert to Monday=0 … Sunday=6
#let monday-index(y, m, d) = int(calc.rem(zeller-h(y, m, d) + 5, 7))

// Get day of year for week calculation
#let day-of-year(year, month, day) = {
  let days_in_months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  if is-leap(year) {
    days_in_months.at(1) = 29
  }

  let total = day
  for i in range(0, month - 1) {
    total += days_in_months.at(i)
  }
  total
}

// Get weekday name using Zeller's congruence
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

// Get month name
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

// Get ISO week number
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
    let dec31_doy = if is-leap(year) { 366 } else { 365 }
    let dec31_dow = calc.rem(jan1_dow + dec31_doy - 1, 7)
    if dec31_dow < 4 { 1 } else { 53 }
  } else {
    week
  }
}