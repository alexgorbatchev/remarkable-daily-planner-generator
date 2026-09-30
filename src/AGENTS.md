---
created_on: 2026-09-29 20:19
last_modified: 2026-09-30 13:25
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
- Gray date links preserve the current view: Day to Day, Notes to Notes, and Standup to Standup. Put the previous included date first, followed by the configured number of upcoming dates; skip excluded weekends and omit destinations outside the planner year.
- Standups default off. `STANDUP.enabled` sets the default; explicit `standup` input overrides it. Both generation and links must use `STANDUP_ENABLED`.
- Standup pages have no separate body heading. Keep the Standup navigation tab and fill the space below the daily navigation with horizontal writing lines.
- Preserve the portrait toolbar clearance: blank top gap, left-aligned upcoming dates above the main header at their existing vertical position, compact bold date, and no extra left inset.
- Daily headers use one left-aligned row: `YYYY Mon DD Weekday Notes Standup`. Bold the date, zero-pad the day, use short weekdays (`Mon`, `Tue`, etc.), and link the year to the annual calendar. Keep all tabs visible and highlight the active one; the weekday links to Day, with Notes and enabled Standup linking to the same date. Disabled Standup stays visible as plain text.
- Within the bold date, only `YYYY` is clickable. Keep `Mon DD` as plain text and keep the year link's hitbox clear of it.
- Special-date labels sit beneath the weekday to leave room for navigation.
- Active tabs use a black box with 4pt padding and white text. Size the text's bottom edge to its glyph bounds so descenders remain inside the padded box.
- Keep the touch areas of upcoming-date links separate from the main header links.

## Verification

- With the current 2026 weekday configuration, expect 523 pages without standups and 784 with them; including weekends yields 731 and 1096.
- Check calendar, day, notes, and standup pages plus holiday labels and year-end navigation when those areas change.
- Render PDFs to inspect layout and verify link destinations for navigation changes.
- Shared testing and coverage requirements are in [../AGENTS.md](../AGENTS.md); compile smoke checks do not measure coverage.
