// Inspect generated native content, including nested grid cells and links.
#let descendants(value, element) = {
  let matches = ()
  if type(value) == content {
    if value.func() == element { matches.push(value) }
    for field in value.fields().values() { matches += descendants(field, element) }
  } else if type(value) == array {
    for item in value { matches += descendants(item, element) }
  }
  matches
}
#let plain(value) = descendants(value, text).map(it => it.text).join("", default: "")
