---
created_on: 2026-09-29 20:19
last_modified: 2026-09-30 14:06
status: current
---

# Typst planner templates

The templates generate an annual calendar followed by chronological blocks of daily pages.

## Commands

- Compile both standup settings without overwriting build outputs: `just test`
- Inspect a day page: `OUT_DIR=.tmp/preview just preview .tmp/planner-test.pdf 2:day`
- Inspect a standup page: `OUT_DIR=.tmp/preview just preview .tmp/planner-standup-test.pdf 524:standup`

## Layout and navigation contracts

- Parameterize reusable components by date and configuration; do not embed one date in a shared view.
- Keep page blocks ordered Calendar, Day, Notes, then optional Standup. Append standups to preserve Day/Notes page positions.
- Apply the same weekend filter to all daily blocks and navigation destinations.
- Date label helpers in `lib/calendar.typ` are shared by pages and links; keep their targets consistent.
- Gray date links preserve the current view by default; `quick_jump_same_view: false` selects Day destinations. `quick_jump_previous` controls the first previous-date link; `quick_jump_count` counts only upcoming dates, so zero permits previous-only navigation. Skip excluded weekends and omit destinations outside the planner year.
- Standups default off. `STANDUP.enabled` sets the default; explicit `standup` input overrides it. Both generation and links must use `STANDUP_ENABLED`.
- Standup pages have no separate body heading by default; `STANDUP.title_show` enables the configurable title. Writing lines fill the remaining height in either mode.
- Preserve the default portrait toolbar clearance and gray navigator's vertical position. Both navigation rows have configurable horizontal alignment.
- Daily headers default to `YYYY Mon DD Weekday Notes Standup`, with a bold date and short weekdays. Order, labels, date-component order and separator, month/weekday abbreviation, day padding, spacing, and inactive Standup visibility are configurable. Omit tokens from `navigation_order` to hide them.
- Within the date, only `YYYY` may link to the annual calendar; `year_link` controls that link. Keep month/day text plain and the year link's hitbox clear of it.
- Special-date labels sit beneath the weekday to leave room for navigation.
- Active tabs default to a black box with 4pt padding and white text; colors, padding, and box/underline/none styles are configurable. Size boxed text's bottom edge to its glyph bounds so descenders remain inside the padded box.
- Keep the touch areas of upcoming-date links separate from the main header links.
- Keep navigation components in `lib/navigation.typ`, date picker logic in `lib/date-navigator.typ`, and shared page geometry in `lib/layout.typ`. Components accept settings dictionaries with defaults from `config.typ`; views must pass the same header settings to content and geometry.

## Verification

- With the current 2026 weekday configuration, expect 523 pages without standups and 784 with them; including weekends yields 731 and 1096.
- Check calendar, day, notes, and standup pages plus holiday labels and year-end navigation when those areas change.
- Render PDFs to inspect layout and verify link destinations for navigation changes.
- `tests/navigation.typ` includes date-window and optional-title assertions. `tests/render.typ` renders complete linked planners with the presets in `tests/presets.typ`; do not replace actual destinations with placeholder labels.
- Shared testing and coverage requirements are in [../AGENTS.md](../AGENTS.md); compile smoke checks do not measure coverage.
