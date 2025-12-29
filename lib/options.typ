// Option parsing helpers

// Boolean parsing helper for string sys.inputs values.
#let parse-bool(v, default: false) = {
  if v == "" {
    default
  } else if (v == "true") or (v == "1") or (v == "yes") {
    true
  } else if (v == "false") or (v == "0") or (v == "no") {
    false
  } else {
    default
  }
}

// Reads a boolean sys.inputs value (string), falling back to default.
#let input-bool(key, default: false) = parse-bool(sys.inputs.at(key, default: ""), default: default)

// Weekend inclusion control.
// Default: weekends are excluded.
// Set `--input weekends=true` to include Sat/Sun.
// Backward-compat: if `weekends` isn't set, respects legacy `exclude-weekends`.
#let weekends() = {
  let w = sys.inputs.at("weekends", default: "")
  if w != "" {
    parse-bool(w, default: false)
  } else {
    let ex = sys.inputs.at("exclude-weekends", default: "")
    if ex != "" { not parse-bool(ex, default: true) } else { false }
  }
}
