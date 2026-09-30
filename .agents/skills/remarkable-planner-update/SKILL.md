---
name: remarkable-planner-update
description: Use when updating future pages in an existing reMarkable planner while preserving editable native handwriting. Do not use for an ordinary fresh PDF build.
author: alexgorbatchev
metadata:
  created_on: 2026-09-30 07:29
  last_modified: 2026-09-30 16:22
  status: current
---

1. Establish the source document, inclusive cutoff date, new title, country, and
   whether to add missing Standup pages. Reuse explicit conversation decisions.
   Do not infer the cutoff from today or a filename.
2. Read [setup](references/setup.md), [assembly](references/assembly.md), and
   [verification](references/verification.md). Use the repository's native
   migration runner; do not rerun date-specific scripts from earlier migrations.
3. Run `just migrate prepare` with the established inputs. Preparation downloads a
   fresh native backup and writes a background PDF, page map, and manifest into
   an unused `.tmp/` directory. For local verification, use `--source-archive`.
4. Inspect the background PDF and the reported page/link counts before publishing.
   Keep all original pages, including handwritten future pages and previously
   appended Standups. Add only missing requested future Standups. Stop on ambiguous
   inventory or writing-area geometry; do not discard ink to make the run pass.
5. Follow [cloud transfer](references/cloud.md). Publish only with authorization
   for that result. `just migrate publish RUN_DIR` creates a separate document.
6. Have the user open the new document on the tablet, return to My files, and sync.
   Run `just migrate resume RUN_DIR`. If native page IDs are absent, leave the run
   pending and repeat resume after the user syncs. Never invent page IDs or CRDT
   state, or flatten handwriting into the PDF.
7. Require the run's `cloud-verification.json` to report PASS and the saved stage
   to be `complete`. Verify native bytes, page associations, PDF hash, and original
   preservation; distinguish cloud checks from observed tablet editing.
8. Retain every run, temporary script, backup, page map, and verification log.
   Return the document title, cutoff, page count, native-file count, and run path.

Use `just migrate status RUN_DIR` to inspect saved state without cloud access.
Resume the same run after ambiguous upload failures; never publish another copy
solely because an upload timed out. Use `rmapi` for this authorized working flow
while the remarkable CLI fixes are in flight. Do not add an unverified transport
adapter or execute unrelated downloaded scripts.
