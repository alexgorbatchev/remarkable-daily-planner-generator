# Native page mapping and backgrounds

The runner inventories every PDF page by logical identity `(kind, date)` and
matches physical PDF indices to the downloaded native page IDs. It supports the
observed legacy `pages` / `redirectionPageMap` and modern `cPages` formats. Missing,
duplicate, deleted, inserted, or unsupported native mappings stop the run.

Preparation recognizes the exercised old headers and current default headers.
For custom headers, supply `--source-map PAGE_MAP_JSON`. That map must contain
`pdf_sha256` matching the downloaded background PDF and a `pages` array with one
`kind` and `date` per physical page. Calendar has `date: null`; daily kinds are
`day`, `notes`, and `standup`. Earlier runs emit this file as `page-map.json`.
Never reuse an inventory based only on matching filenames or page counts.

Keep source page order and existing page types. Preserve the calendar and all
backgrounds before the cutoff. Replace selected future backgrounds and append
only missing future Standups. `--no-standup` retains existing Standups. It does
not add new ones; incomplete future Standup link targets stop preparation.
The source must contain a complete annual Day and Notes calendar; weekend
inclusion is derived from those verified dates. Country is an explicit option.

The Typst migration template reserves the source Notes grid origin for annotated
future Notes pages. Validation compares its tile dimensions, spacing, and origin
against the original. Annotated future Day/Standup replacement is currently
accepted only when decoded page content is identical. Otherwise the runner stops;
a reviewed geometry override needs implementation before migrating those layouts.

The background assembler copies pages without native ink and rebuilds every
internal PDF link through explicit source-to-output maps. Validation resolves
all output links and checks their destinations and touch rectangles. Unsupported
annotations and unmapped links fail instead of being removed or redirected.

The tablet initializes the destination's native page IDs. Attachment renames
source `.rm` entries to their mapped destination IDs while retaining every byte.
It copies page tags, document tags, and viewport settings and preserves the
actual target schema and page ordering. New ink already in the destination is
never overwritten. Unknown native archive attachments stop the run.
