// Special dates definitions and helpers

// File format (CSV in repo root):
//   date,style,label
// Where `date` is YYYY-MM-DD.
// For now, `style` supports: "strike", "fade".

#let parse-date(date) = {
  let parts = date.split("-")
  if parts.len() != 3 { return none }

  let y = int(parts.at(0, default: ""))
  let m = int(parts.at(1, default: ""))
  let d = int(parts.at(2, default: ""))
  (year: y, month: m, day: d)
}

#let load-special-dates-file(year, country) = {
  let path = "../../dates-" + str(year) + "-" + country + ".csv"
  let rows = csv(path, row-type: dictionary)

  let out = ()
  for row in rows {
    let parsed = parse-date(row.date)
    if parsed == none { continue }
    if parsed.year != year { continue }

    out.push((
      month: parsed.month,
      day: parsed.day,
      style: row.style,
      label: row.label,
    ))
  }

  out
}

// Returns a list of special date definitions for a country/year, or `false` to disable.
// Each entry is a dictionary: (month: int, day: int, style: string, label: string)
#let special-dates(year, country) = {
  // Allow disabling special dates via `--input country=none` / `false`.
  if (country == "false") or (country == "none") or (country == "off") {
    return false
  }

  // For now, only known combo(s) are loaded to avoid failing builds
  // when a file isn't present yet.
  if (year == 2026) and ((country == "usa") or (country == "ca-on")) {
    return load-special-dates-file(year, country)
  }

  ()
}

// Returns a special date entry for a given date from a list, or `none`.
#let special-date-entry(special_dates, month, day) = {
  if special_dates == false { return none }

  for h in special_dates {
    if (h.month == month) and (h.day == day) { return h }
  }

  none
}
