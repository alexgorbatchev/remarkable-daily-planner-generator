# Verify native migrations

`preparation-verification.json` records the PDF hash, page count, link count,
source native-file count, and added pages. Preparation verifies date/type
inventory, complete annual Day/Notes coverage, selected page dimensions,
annotated Notes grid geometry, and every rebuilt internal link.

Inspect rendered complete pages before publishing: calendar, historical annotated
Day and Notes pages, cutoff boundaries, handwritten future pages, first/last new
Standups, holidays, and year-end navigation. Raw stroke hashes establish byte
preservation; they do not establish visual alignment beneath a changed background.
Do not embed rendered ink or preview overlays into the migration PDF.

Attachment verifies every native stroke byte and its logical output page,
including metadata-only files and future notes. It preserves the initialized
native page identity, page tags, viewport settings, and background PDF. Fresh
source and destination snapshots guard against concurrent cloud edits.

Require saved stage `complete` and `cloud-verification.json` with PASS, native-file
count, PDF hash, and `original_files_unchanged: true`. Backups, stroke maps, and
rmapi command logs remain in the run directory. Do not claim tablet synchronization
or select/move/erase behavior was checked unless the user observed it.

Run `just migration-test` and the assembly helper tests when changing the runner.
Work red/green and temporarily disable native copying or link mapping to require
meaningful test failures; restore the change before the final successful checks.
