# Page selection and composition

Contents: [inventory](#build-an-inventory-first), [backgrounds and ink](#select-backgrounds-and-retain-ink),
[helper](#use-the-assembly-helper), [compression](#compress-before-writing),
[worked mapping](#worked-mapping-first-2026-migration).

## Build an inventory first

Use zero-based indices in Python and `remarkable --page`; use one-based page
numbers in Poppler's `-f`/`-l` flags and user-facing reports. Record both.

Derive dates from the actual year and weekend filter. Check extracted header text,
page types, and source link targets. Upcoming-date navigation also contains dates:
do not identify a page by the first arbitrary date fragment in extracted text.

For an unmodified planner with `N` included dates and zero-based date offset `i`:

| Page type | Source index |
| --- | --- |
| Calendar | `0` |
| Day | `1 + i` |
| Notes | `1 + N + i` |
| Full-year Standup block, if present | `1 + 2*N + i` |

These formulas require verified uninterrupted blocks. A migrated planner with
partial Standup pages, user-inserted pages, or changed page order needs an explicit
inventory. Reuse earlier provenance only after matching its source/output hashes
to the current files. Do not rerun first-migration formulas on a migrated planner.

## Select backgrounds and retain ink

Keep the old calendar and all backgrounds before the inclusive cutoff by default.
For each later date/type, select its replacement background. Preserve native ink
even on dates after the cutoff. Retain existing added page types, replacing their
future backgrounds if requested; append only dates/types that are missing.

Generate a full template into scratch space, then select the needed pages:

```bash
typst compile --root . --input year=2026 --input country=usa \
  --input weekends=false --input standup=true src/index.typ .tmp/new-template.pdf
```

Adjust values to the verified migration inputs. Do not use `just build` for this
scratch step because it overwrites the normal `build/planner-YEAR.pdf` output.

Export each downloaded, nonzero-length `.rm` file locally with the exact width
and height read from its corresponding PDF page in points:

```bash
remarkable stroke export "$STROKE_FILE" --width "$PAGE_WIDTH" \
  --height "$PAGE_HEIGHT" --output "$OVERLAY_SVG"
```

Convert that SVG with `cairosvg.svg2pdf(url=..., dpi=72, write_to=...)`. The SVG's
unitless dimensions must map to PDF points, not CairoSVG's default 96-DPI scale.
Keep the generated viewBox, including its negative horizontal origin. Do not add
an opaque background, rescale to arbitrary device pixels, or re-center strokes.

Compare an overlay on the old background to a `remarkable doc render` reference
before processing all pages. Check colors, line weight, highlighting, alignment,
and marks near page edges. Unsupported stroke conversion is a blocker, not a
reason to silently skip that page. Keep original native data regardless.

## Use the assembly helper

Load `scripts/assemble.py` with `runpy.run_path` from a task-specific driver, then
call its `assemble` function with:

| Argument | Meaning |
| --- | --- |
| `sources` | Source name to `Path`, e.g. `{"old": OLD_PATH, "new": NEW_PATH}` |
| `selections` | Ordered `(source_name, zero_based_source_page)` tuples |
| `destinations` | `(source_name, zero_based_source_page)` to final zero-based page |
| `overlays` | Final zero-based page to single-page transparent PDF `Path` |
| `output` | A new, unused `Path`; existing outputs are rejected |

Map link destinations for **both** sources, including pages whose background is
replaced. For example, an old calendar's link to old September 30 must reach the
selected new September 30 page. Never key destinations solely by source index or
PDF object number: different sources can reuse those numbers for different pages.

The helper strips annotations during page cloning, overlays ink, then rebuilds
internal links against the completed output page tree. It supports both direct
`/Dest` links and `/A` actions with `/S /GoTo` and `/D`, including indirect arrays.
It preserves the destination's fit/zoom coordinates and annotation rectangle.
It rejects missing targets, named destinations, non-link annotations, external
actions, rotated overlays, and mismatched overlay dimensions. It does not import
document metadata, source bookmarks, or tagged-PDF structure. Extend the workflow
explicitly if those features are required; do not silently remove them.

Save a provenance record per output page: logical date/type, source file hash,
source index, final index, original native page ID, and stroke hash when present.
An overlay map is keyed by **output** index; derive it from native page identity
if the output order changes. Do not assume handwriting index equals output index.

## Compress before writing

The helper compresses content streams and removes duplicate/unreferenced objects
in the same writer before writing. Compressing by cloning an already assembled,
heavily linked document can increase file size and exceed Python's recursion
limit. If a separate clone is necessary, follow pypdf's documented recursion-limit
guidance; validate links afterward. Do not trade vector ink for raster screenshots.

## Worked mapping: first 2026 migration

For the verified USA/no-weekends original: `N=261`, 523 original pages, September
30 offset `194`, and 67 dates remaining. Preserve Calendar plus all Day/Notes slots,
use new Day backgrounds at indices `195..261` and new Notes at `456..522`, and
append new full-template Standup indices `717..783` as output indices `523..589`.
The result has 590 pages. Keep September 30 Notes and October 1 Notes handwriting.
Treat these numbers as an example, not defaults for subsequent migrations.
