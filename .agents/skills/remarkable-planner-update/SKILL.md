---
name: remarkable-planner-update
description: Use when updating future pages in an existing reMarkable planner while preserving editable native handwriting. Do not use for an ordinary fresh PDF build.
author: alexgorbatchev
metadata:
  created_on: 2026-09-30 07:29
  last_modified: 2026-09-30 20:51
  status: current
---

1. Establish the source document, inclusive cutoff date, new title, country, and
   whether to add missing Standup pages. Reuse explicit conversation decisions.
   Do not infer the cutoff from today or a filename.
2. Read [setup](references/setup.md), [assembly](references/assembly.md),
   [cloud transfer](references/cloud.md), and [verification](references/verification.md).
   Read `AGENT=1 remarkable skill` before operational commands. Use only
   `remarkable` for cloud access, with `AGENT=1` on every invocation.
3. Check the required capabilities against the installed CLI's embedded skill.
   If native archive export, new PDF upload, or required tag/viewport transfer is
   unavailable, report the missing operation and stop that dependent cloud step.
   Never use rmapi, rm-upload, direct cloud requests, or old temporary scripts as
   a substitute. The existing runner's cloud paths still use rmapi; do not run
   `prepare --source`, `publish`, or `resume` until that integration is replaced.
4. With an existing verified native archive, run local preparation using
   `just migrate prepare --source-archive` and the established inputs. Save the
   background PDF, page map, and manifest in an unused `.tmp/` directory.
5. Inspect the background PDF and the reported page/link counts before publishing.
   Keep all original pages, including handwritten future pages and previously
   appended Standups. Add only missing requested future Standups. Stop on ambiguous
   inventory or writing-area geometry; do not discard ink to make the run pass.
6. Publish only with authorization for that result and a supported remarkable
   command. Preserve the original and create a separate destination. Have the user
   open it on the tablet, return to My files, and sync to initialize native page IDs.
7. Import mapped native files with `remarkable doc import` as described in
   [cloud transfer](references/cloud.md). Never invent page IDs or CRDT state,
   discard conflicting destination ink, or flatten handwriting into the PDF.
8. Verify native bytes, page associations, PDF hash, and original preservation.
   Require successful exit status and `state: verified` from the import. Save
   verification evidence; distinguish cloud checks from observed tablet editing.
9. Retain every run, temporary script, backup, page map, and verification log.
   Return the document title, cutoff, page count, native-file count, and run path.

Use `just migrate status RUN_DIR` to inspect saved state without cloud access.
After an ambiguous import, inspect the destination before selecting the next
action. Never blindly repeat an import, create another copy because of a timeout,
or modify saved document IDs to bypass a conflict.
