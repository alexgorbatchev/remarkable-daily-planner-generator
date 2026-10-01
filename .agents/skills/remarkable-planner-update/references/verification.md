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

Require every source native file, including metadata-only files and future notes,
to appear once in the import mapping at its logical output page. Successful
remarkable import verifies native bytes and committed page associations and keeps
the destination PDF and `.content` bytes intact. Download imported native files
again with `--no-cache` and compare their hashes to the source. Verify source tags
and viewport settings separately; unchanged destination content does not prove
that source settings were copied. Stop if required preservation cannot be checked.

Require exit status zero and `state: verified` from remarkable import. Retain
stdout, stderr, the mapping, source backups, and downloaded verification files.
Check destination PDF hash, native page associations, and original preservation.
The existing runner's `cloud-verification.json` and `complete` stage belong to
its old cloud integration; do not fabricate them for a manual remarkable import.
Do not claim tablet synchronization or select/move/erase behavior was checked
unless the user observed it.

Run `just migration-test` and the assembly helper tests when changing the runner.
Work red/green and temporarily disable native copying or link mapping to require
meaningful test failures; restore the change before the final successful checks.
