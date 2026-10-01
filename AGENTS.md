---
created_on: 2026-09-29 20:19
last_modified: 2026-09-30 20:51
status: current
---

# Planner contributor guidance

This repository generates linked PDF planners with Typst and Bash.

## Commands

- List tasks: `just`
- Local native planner migration preparation: `just migrate --help`; setup: `just migration-setup`; checks: `just migration-test`. The runner's cloud commands remain blocked pending the remarkable CLI integration described in [scripts/AGENTS.md](scripts/AGENTS.md).
- Build and open on macOS: `just build 2026 --open`
- Include standups: `just build 2026 --standup --open`
- Rebuild on save: `just build 2026 --watch`
- Check shell syntax and smoke-compile both standup settings: `just check`
- Inspect PDF page count: `pdfinfo .tmp/planner-test.pdf`
- Render a page for inspection: `OUT_DIR=.tmp/preview just preview .tmp/planner-test.pdf 2:day`

## Setup and scope

- Builds require Typst; recipes require just and Bash.
- Preview rendering uses Poppler or ImageMagick; default shadows require ImageMagick.
- Batch README updates require ripgrep. PDF inspection uses Poppler's `pdfinfo` and `pdftotext`.
- Template guidance: [src/AGENTS.md](src/AGENTS.md).
- Automation guidance: [scripts/AGENTS.md](scripts/AGENTS.md).
- Use Context7 for documentation when available; otherwise consult official online docs.
- Read applicable skills fully before modifying code. Ground changes and completion claims in inspected source and execution evidence.

## Conventions and validation

- New global variables use SHOUT_CASE; keep unrelated existing names unchanged.
- Use `rg` or codegraph for searches. Never use heredocs.
- Keep scratch files in `.tmp/`; use `.workspaces/` for worktrees, based on main by default.
- Keep temporary scripts used for planner generation, migration, and verification for future reuse; do not delete them during cleanup.
- `just test` checks configuration-aware navigation content and compiles default and custom planner fixtures; it does not measure coverage or inspect visual layout.
- Keep navigation appearance and behavior configurable through `src/config.typ`; preserve the approved appearance as the defaults. Regression fixtures must adapt to configured counts, labels, styles, and alignment.
- For behavior changes outside `scripts/`, update corresponding tests and require 90% code coverage. No Typst coverage tooling is currently configured; report that limitation rather than claiming coverage.
- Where tests exist, work red/green and temporarily disable the change to confirm the tests fail.
- For layout changes, render affected pages and inspect them; compilation alone does not establish visual correctness.

## Boundaries

- Always preserve other agents' work and staged changes; stop and resync on unexpected index locks or conflicts.
- Record new user instructions in the appropriate `AGENTS.md`; check first if they conflict with existing guidance.
- Keep shell argument handling and output modes unchanged unless requested; do not introduce compatibility wrappers.
- Ask first before expanding scope. Do not replace annotated reMarkable documents as part of an ordinary PDF build.
- Use the `remarkable` CLI for all reMarkable access, including native planner migrations. Read `AGENT=1 remarkable skill` before operational commands and set `AGENT=1` on every invocation.
- The previous rmapi migration exception is revoked. Never use rmapi, rm-upload, or a custom cloud API client as a substitute. Report missing remarkable capabilities instead of bypassing them. Keep the original document and all migration scripts, backups, maps, and verification logs.
- Planner updates must preserve original handwriting as editable native reMarkable strokes. Never flatten existing strokes into PDF artwork as the migration result; retain the original document and native backup.
- Build commands overwrite their named output PDFs. Use `.tmp/` for verification and preserve user-generated PDFs and tracked preview assets.
- Never publish releases, tags, packages, or production deployments without explicit user authorization.
