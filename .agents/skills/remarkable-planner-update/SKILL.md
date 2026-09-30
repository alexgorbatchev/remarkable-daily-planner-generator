---
name: remarkable-planner-update
description: >-
  Use when slicing, merging, or replacing pages in an existing reMarkable planner
  PDF while preserving notes, drawings, and navigation, or updating only future
  planner dates. Use for this migration's download and upload steps. Do not use
  for an ordinary fresh Typst build or unrelated PDF editing.
author: alexgorbatchev
metadata:
  created_on: 2026-09-30 07:29
  last_modified: 2026-09-30 07:29
  status: current
---

1. Establish the source document, first date to update **inclusive**, weekend/locale
   settings, desired page types, output filename, and whether upload is requested.
   Use established conversation decisions; ask only for missing choices that change
   which pages or handwriting survive. Never infer the cutoff from today's date.
2. Read the PDF and Python skills before manipulating PDFs. Read
   [setup](references/setup.md) for dependencies and
   [cloud transfer](references/cloud.md) when accessing reMarkable.
3. Download the current base PDF, native handwriting, and page inventory into a
   unique project-local `.tmp/` directory. Hash the inputs. Match the base PDF to
   a repository variant when possible; filename and page count alone do not prove
   a match. Do not put personal document data into this skill or Git.
4. Inventory **every** page by date, page type, source index, native page ID, and
   stroke presence. Inspect dates beyond the cutoff too. A future page is not
   necessarily empty, and a nonempty `.rm` file can contain only metadata.
5. Read [page assembly](references/assembly.md). Construct explicit source-to-output
   maps before combining pages. Keep past backgrounds and all existing handwriting;
   apply new backgrounds only within the requested range. Add only missing page
   types/dates. Retain existing Standup pages on subsequent migrations.
6. Disclose the output model before assembly: a standalone PDF embeds handwriting
   as artwork; it does not preserve native reMarkable stroke editability. Keep
   original `.rm` files or the native archive separately. If editable strokes are
   mandatory, stop the PDF-only workflow and establish a native-document workflow.
7. Generate the new template with the established configuration into `.tmp/`.
   Convert native strokes to transparent vector overlays at the source page's exact
   size. Build a fresh PDF with [the assembly helper](scripts/assemble.py).
   Never overwrite source files or silently discard an unsupported annotation.
8. Run the structural and visual checks in [verification](references/verification.md).
   Save the page map, input hashes, stroke hashes, and verification log with the
   local working files. Return an artifact only after those checks pass.
9. Upload only when the user has explicitly authorized uploading this result.
   Follow [cloud transfer](references/cloud.md), create a distinct document name,
   and verify the downloaded upload against the local PDF. Never interpret a local
   build request as upload authorization; do not ask again if already authorized.

## Deliver the result

Provide the local PDF, page count, cutoff date, added page counts, and validation
result. State whether anything was uploaded. Repeat the embedded-handwriting
limitation when delivering a PDF that contains prior notes. Distinguish verified
cloud upload from unobserved tablet synchronization.

## Keep the workflow repeatable

- Use logical identity `(page type, date)` to connect old and new templates. PDF
  object numbers and page indices belong to their source document, not globally.
- Do not apply yesterday's stroke backup to today's downloaded base PDF. The base
  may already contain embedded historical handwriting; overlay only its current
  native stroke layers to avoid duplicating ink.
- Preserve the downloaded page order unless the user requests a reorder. Check
  inserted, duplicated, removed, or previously appended pages before using formulas.
- Do not fix an unmapped link by pointing it to an arbitrary nearby page, deleting
  it, or importing unselected pages. Resolve the intended destination explicitly.
- Do not replace pages with screenshots to make annotation preservation appear
  successful. Keep searchable template text, vector handwriting, and working links.
- Keep upload credentials out of logs, commands containing literal tokens, and
  generated documentation. Reuse the CLI's existing authentication.
