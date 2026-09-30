# Resumable transfer with rmapi

The current runner uses the user-authorized rmapi flow while remarkable CLI fixes
are in flight. Do not substitute another tool or claim an unsupported remarkable
upload command exists. Reuse existing rmapi authentication.

Prepare a reviewable result; this command downloads but does not upload:

```bash
just migrate prepare --source SOURCE_ID_OR_PATH --from YYYY-MM-DD --title 'NEW TITLE' --rmapi PATH_TO_RMAPI
```

The printed run directory contains `migration.json`, native backups, the
background PDF, `page-map.json`, and preparation verification. Choose an unused
new title. For custom headers, supply a hash-verified `--source-map`. A later
migration should use the most recently edited document as its source.

Once uploading this result is authorized, run:

```bash
just migrate publish RUN_DIR
```

Open the uploaded document on the tablet, return to My files, and let it sync.
Then run:

```bash
just migrate resume RUN_DIR
just migrate status RUN_DIR
```

Resume waits if page IDs are not initialized. It attaches native strokes only
after freshly downloading and checking both documents. Source changes require a
new preparation so recent handwriting is not lost. Conflicting destination ink
stops the operation. The original is never a replacement target.

rmapi `put --force` deletes and recreates the separate staging document; it is
not an in-place file merge. The runner retains a complete native staging archive
and its tablet-generated UUIDs before that operation. It verifies the downloaded
upload and the original afterward. If interrupted after deletion, resume restores
the saved staging archive using normal put only when its title is absent.

If an upload fails or times out, rerun the same publish/resume command with the
same run directory. The saved upload-intent stage determines whether an existing
matching document can be adopted. A completed resume verifies again without
uploading twice. Never change the saved IDs, delete backups, or blindly retry
`put --force` manually. Tablet synchronization and editing need separate observation.
