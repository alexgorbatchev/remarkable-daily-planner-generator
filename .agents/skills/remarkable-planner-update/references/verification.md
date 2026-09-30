# Verify before delivery or upload

Write a validation log with observed values and failing page indices. A successful
write, matching page count, or screenshot alone is insufficient.

## Structural checks

- Open the final PDF again with `PdfReader(..., strict=True)` and run `pdfinfo`.
- Assert the exact page inventory: expected count, order, date/type for every page,
  and exactly the requested added pages. Detect duplicates and missing dates.
- Resolve every internal destination against the **final** page tree. Require
  each page's target set to match its semantic navigation: calendar, same-date
  counterparts, and the next configured number of included Day dates.
- Keep historical navigation unchanged unless requested. Future pages may gain a
  Standup link only when that date's Standup page exists in the output.
- Verify each final MediaBox and rotation against the selected source background.
- Compare extracted template text against that background. Old PDFs can extract
  date, upcoming-date row, and weekday in a different order from new templates;
  validate semantic fields rather than requiring one contiguous text phrase.
- Hash every native stroke input. Verify every inventoried nonempty stroke file
  has a corresponding converted overlay and output mapping. File size alone does
  not prove visible ink or fidelity; retain metadata-only files too.
- For pages without overlays, compare decoded content streams to the selected
  template. For pages with overlays, check the added artwork and provenance.
- Require no unexpected rasterization. The exercised vector planner workflow has
  zero image objects; do not use that invariant for a source that intentionally
  contains images.

## Visual checks

Render with Poppler and inspect complete pages, not text extraction alone:

- Calendar and a heavily annotated historical Day and Notes page.
- Last unchanged date and first updated date, for each affected page type.
- Any future page that already contains handwriting or drawings.
- First and last appended Standup pages, holiday labels, and year-end navigation.
- Any page whose size, writing area, crop, or orientation changes.

Check old-versus-new ink position, highlighter colors, handwriting at page edges,
header toolbar clearance, and overlap with the replacement template. If the body
layout moved, preserving raw coordinates may be wrong: retain that page's old
background or establish an explicit transformation with the user.

After compression, repeat the structural checks. Render a representative drawing
page before/after at the same dimensions and compare the images to confirm no
visual change. Keep originals and the new output as separate files.

## Exercise mapping failures when adapting code

Run the bundled tests for the assembly helper. For a changed mapping algorithm,
temporarily disable target remapping in an isolated scratch copy and require the
navigation checks to fail, then restore it. Never mutate the user's source PDF or
the deliverable to perform this negative check.

Record page count, link count, included stroke-file count, source/output hashes,
and inspected page numbers. Do not claim all handwriting is visually identical
based solely on hash/size accounting or a handful of rendered samples.
