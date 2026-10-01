# Cloud transfer with remarkable

Read `AGENT=1 remarkable skill` before operational commands and set `AGENT=1`
on every invocation. Use only the commands and options in that installed skill.
The earlier rmapi exception is revoked. Never use rmapi, rm-upload, direct cloud
requests, or preserved temporary scripts as a substitute for a missing command.

## Capability check

The installed 1.1.0 CLI supports native `doc import` into an existing document.
It does not expose native archive export, new PDF upload, or transfer of source
tags/viewport settings. Recheck the embedded skill after a CLI update; report a
missing required operation and stop its dependent step instead of inventing flags.

The repository runner still uses the old client for `prepare --source`, `publish`,
and `resume`. Do not invoke these paths until its cloud integration is replaced.
Local preparation from an existing verified archive is available:

```bash
just migrate prepare --source-archive ARCHIVE --from YYYY-MM-DD --title 'NEW TITLE'
just migrate status RUN_DIR
```

Do not construct an incomplete archive from PDF and stroke exports: those exports
do not include all native document metadata. Retain the original native backup.

## Native import into a separate initialized destination

Use a separate destination whose background PDF matches the reviewed output.
Creating that destination requires a supported upload operation; if unavailable,
report the missing capability. Never import into the source document.
Have the user open the destination on the tablet, return to My files, and sync.
Resolve its UUID and inspect its actual native page IDs:

```bash
AGENT=1 remarkable doc list --query 'NEW TITLE' --type DocumentType --no-cache
AGENT=1 remarkable doc inspect DESTINATION_UUID --pages --no-cache
```

Reject ambiguous titles and uninitialized or conflicting pages. Import accepts
v6 native files; stop on unsupported source formats. Extract native
files from the verified source archive without changing their bytes. Build the
mapping from the reviewed source-to-output page map, using 0-based destination
indexes and paths relative to the mapping file's directory or absolute paths:

```json
[
  {"source": "native/page-000.rm", "page": 0},
  {"source": "native/page-457.rm", "page": 457}
]
```

The indexes above illustrate the schema; derive every actual index from the run's
map. Include every source native file, including future notes and metadata-only
files. Preserve source tags and viewport requirements separately: import retains
destination `.content` bytes and does not transfer those settings from the source.

Once importing this result is authorized and preservation checks pass:

```bash
AGENT=1 remarkable doc import DESTINATION_UUID --mapping RUN_DIR/import-map.json --no-cache
```

Save stdout, stderr, and exit status in the run directory. Require exit status
zero and `state: verified`. For `staged`, `commit-unknown`, or `committed` failures,
inspect the destination and downloaded native bytes before selecting the next
action; never blindly retry an import. Follow [verification](verification.md).
Cloud verification and observed tablet editability are separate checks.
