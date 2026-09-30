#import "../src/config.typ" as config

#let HEADER_BLUE = (
  ..config.header,
  height: 18mm, quick_jump_height: 5mm, day_label_gap: 2mm,
  date_font_size: 10pt, weekday_font_size: 10pt, navigation_font_size: 10pt,
  date_order: ("day", "month", "year"), date_separator: " / ",
  month_short: false, day_zero_pad: false, weekday_short: false,
  notes_label: "Memo", standup_label: "Sync", navigation_gap: 2mm,
  active_box_color: blue, active_text_color: white, active_padding: 3pt,
  quick_jump_count: 3, quick_jump_previous: false,
)
#let HEADER_UNDERLINE = (
  ..HEADER_BLUE,
  navigation_order: ("notes", "date", "day", "standup"), navigation_align: right,
  active_style: "underline", active_text_color: blue,
  active_underline_thickness: 1.5pt, active_underline_offset: 2pt,
  year_link: false, quick_jump_align: right, quick_jump_same_view: false,
)
#let HEADER_PLAIN = (
  ..config.header,
  active_style: "none", navigation_align: center,
  navigation_order: ("date", "day", "notes"), show_disabled_standup: false,
  quick_jump_count: 0, quick_jump_align: center,
)
#let STANDUP_TITLED = (
  ..config.STANDUP,
  title_show: true, title: "Daily sync", title_font_size: 13pt,
  title_gap: 2mm, lines_height: 6mm,
)
