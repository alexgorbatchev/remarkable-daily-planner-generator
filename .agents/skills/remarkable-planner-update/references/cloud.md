# Cloud transfer with remarkable

Read `AGENT=1 remarkable skill` before operational commands. The runner requires
remarkable CLI 1.2+ and sets `AGENT=1` and `--no-cache` on every invocation. It saves
command arguments, stdout, stderr, and exit status in the run directory. Missing
required capabilities stop the dependent step; the earlier rmapi exception is
revoked. Preserve historical scripts and archives without using another client.

## Prepare and review

```bash
just migrate prepare --source SOURCE_UUID --from YYYY-MM-DD --title 'NEW TITLE'
just migrate status RUN_DIR
```

`--source` accepts a UUID, exact title, or remarkable document path. Cloud
preparation uses `doc archive` to download every native attachment with snapshot
evidence; local preparation accepts that ZIP through `--source-archive`. Archive
hashes, sizes, identity, and manifest evidence are checked before use. Native
files are kept as raw bytes. Do not construct an archive from individual PDF and
stroke exports that omit native metadata.

Before preparation, have the user close the source document and finish syncing.
Keep it closed during the migration: tool preferences and read-position changes
alter native content or metadata even when handwriting bytes remain unchanged.
The runner checks every source attachment and requires a fresh preparation after
any source change.

Review `RUN_DIR/background.pdf`, `page-map.json`, and
`preparation-verification.json` before publication. Use an unused title and keep
the original document. The source is downloaded again and compared to the saved
snapshot before cloud writes; source edits require a fresh preparation.

## Publish and initialize

```bash
just migrate publish RUN_DIR
```

The runner calls `doc upload` with the reviewed PDF, new title, and
`RUN_DIR/upload.json` evidence path. The CLI writes durable creation evidence
before staging cloud data. Recovery uses its saved UUID and `doc upload-check`;
if tablet initialization changed the creation hash, the runner inspects that
same UUID and exact PDF instead. An interrupted upload does not cause an
automatic second document. Inspect the saved evidence before retrying a failed
publication with the same command.

At `awaiting_page_ids`, have the user open the new document on the tablet, return
to My files, and sync. Native page IDs must come from that initialized document.
Keep the destination free of new handwriting until transfer completes.

## Resume native transfer

```bash
just migrate resume RUN_DIR
```

The runner downloads both documents, verifies the prepared background and page
structure, and writes a transfer directory containing raw native files,
`import-map.json`, `settings-map.json`, and `stroke-map.json`. Import mappings
use 0-based destination indexes and paths relative to the mapping directory:

```json
[
  {"source": "page-0000.rm", "page": 0}
]
```

Settings mappings cover every original page:

```json
[
  {"source_page": 0, "destination_page": 0}
]
```

These indexes illustrate the schemas; actual values come from the reviewed
page map. The runner imports every original native file, including future notes
and metadata-only files, through `doc import`. The CLI accepts v6 native files
and rejects unsupported formats. It preserves PDF and native content bytes.

The runner then invokes `doc settings transfer SOURCE_UUID DESTINATION_UUID
--mapping SETTINGS_MAP --replace-viewport`. This transfers document tags, mapped
page tags, and source viewport values and field presence. The explicit viewport
replacement applies to the separate migration destination, preserving the source.
The runner checks unrelated destination state before this write.

## Failure recovery and evidence

Stages are `prepared`, `publishing`, `awaiting_page_ids`, `importing`, `settings`,
and `complete`; `preparing` records an unfinished local build. `status` is offline.
Repeat `publish` for publication recovery or `resume` for transfer recovery using
the same saved run. Changed source files, conflicting destination ink, partial
imports, or unexpected settings changes stop the workflow for inspection.

Cloud mutations require successful exit status and `state: verified`. If a
mutation reports `staged`, `commit-unknown`, or `committed` with an error, retain
all logs and inspect the fresh destination. A later resume accepts an import
only when every expected native byte and page association matches. It skips an
already committed settings transfer only when the complete expected result
verifies. Neither path blindly repeats a write.

`cloud-verification.json` records fresh cloud checks of handwriting, PDF, page
mapping, tags, viewport, unrelated destination data, and original preservation.
Follow [verification](verification.md); cloud checks and observed tablet editing
remain separate evidence.
