---
created_on: 2026-09-29 20:19
last_modified: 2026-09-29 20:19
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
- All upcoming-date links lead to Day pages, even from Notes or Standup pages.
- Standups default off. `STANDUP.enabled` sets the default; explicit `standup` input overrides it. Both generation and links must use `STANDUP_ENABLED`.
- Standup pages contain one title and horizontal writing lines filling the remaining height.
- Preserve the portrait toolbar clearance: blank top gap, right-aligned upcoming dates above the main header, compact bold date, and no extra left inset.
- Special-date labels sit beneath the weekday to leave room for navigation.

## Verification

- With the current 2026 weekday configuration, expect 523 pages without standups and 784 with them; including weekends yields 731 and 1096.
- Check calendar, day, notes, and standup pages plus holiday labels and year-end navigation when those areas change.
- Render PDFs to inspect layout and verify link destinations for navigation changes.
- Shared testing and coverage requirements are in [../AGENTS.md](../AGENTS.md); compile smoke checks do not measure coverage.
