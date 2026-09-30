# Download and optional upload

Check the installed CLI's help before using commands. Use existing authentication;
never print credentials. All commands below use user-established document names
and paths stored in task-specific variables, not embedded personal identifiers.

## Download with remarkable

```bash
remarkable doc list --query "$SOURCE_NAME"
remarkable doc inspect "$SOURCE_ID" --pages > "$WORK_DIR/inspection.txt"
remarkable doc cat "$SOURCE_ID" --format pdf > "$WORK_DIR/original.pdf"
remarkable doc sync "$SOURCE_ID" --format rm --output-dir "$WORK_DIR/strokes"
```

Resolve a unique document ID before download; never guess among duplicate titles.
Use a fresh directory. The `pdf` export is the background PDF, not a PDF containing
current native ink. `sync --format rm` exports separate native files, including
zero-byte entries for empty pages. Keep the inventory's page IDs and indices.

If sync times out, rerun the same command without `--force` to resume. Verify
all expected files and sizes against the inventory; retry missing or mismatched
files rather than accepting a partial backup. Reinspect afterward and restart
from a fresh snapshot if the cloud document changed during the download.

Render selected cloud pages for comparison using zero-based page indices:

```bash
remarkable doc render "$SOURCE_ID" --page "$SOURCE_INDEX" \
  --dpi 140 --output "$REFERENCE_PNG"
```

After a cloud update, one client may fail to resolve documents another can see.
Do not interpret that as deletion. Try `--no-cache`, then use the maintained
`rmapi` client to inspect/download. Diagnose discrepancies without modifying the
cloud document or attempting another upload.

## Use rmapi when needed

Obtain the current platform release from `ddvk/rmapi` using its official release
metadata; inspect actual asset names instead of guessing URLs. Keep a temporary
binary under `.tmp/`. The `juruen/rmapi` upstream is archived. Check current
maintenance and protocol support before using any fork.

`rmapi -ni` uses existing authentication without an interactive pairing prompt.
Check `rmapi -ni help`, `help put`, and `help get`. Use `rmapi -ni stat` to verify
names, IDs, and metadata. `get` downloads a native `.rmdoc` archive into the current
directory; run it inside the task's scratch directory.

An `.rmdoc` is a ZIP archive. Inspect its entries before extracting. Read its
`.content` page mapping to connect UUID-named `.rm` files to PDF pages; do not
assume those archive filenames are ordinal `page-NNN.rm` exports. Keep archive
metadata and stroke files together. Do not execute any downloaded content.

## Upload only with authorization for this result

1. Verify the local PDF first. Use the requested distinct title as the PDF basename.
2. Check for an existing document with that title. If one exists, verify whether it
   is this exact completed upload; do not replace it or create a duplicate blindly.
3. Record the original document ID and metadata. Upload the one new file to the
   requested folder, or root if no folder was specified:

```bash
rmapi -ni put "$OUTPUT_PDF" "$REMOTE_FOLDER"
```

4. Do not use `--force` or `--content-only` for a new-document migration. Both can
   replace an existing document; their exact behavior depends on the CLI version.
5. Verify the new name and a distinct ID with `stat`. Download it with `get` in a
   scratch directory, inspect the archive, extract its PDF, and compare SHA-256
   against the local deliverable. Verify page count and original-document presence.
6. If upload status is ambiguous or times out, inspect the remote state before
   retrying. Never run `put` again solely because another client cannot list it.

Report cloud verification accurately; tablet synchronization is separate and is
not verified by a successful cloud upload. Do not upload while creating or testing
this skill or its helper.
