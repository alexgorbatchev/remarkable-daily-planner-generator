---
created_on: 2026-09-29 20:19
last_modified: 2026-10-01 21:05
status: current
---

# Build and preview scripts

Bash scripts build Typst PDFs and render preview images; the root justfile forwards arguments.
The Python migration runner prepares replacement backgrounds from native archives.

## Commands

- Syntax check: `just lint`
- Planner options: `just build --help`
- Batch options: `just build-all --help`
- Preview options: `just preview --help`
- Compile smoke checks: `just test`
- Native migration setup and checks: `just migration-setup`, `just migration-test`.
- Cloud migration preparation: `just migrate prepare --source UUID --from YYYY-MM-DD --title 'NEW TITLE'`.
- Offline migration preparation: `just migrate prepare --source-archive ARCHIVE --from YYYY-MM-DD --title 'NEW TITLE'`.
- Publish the reviewed PDF: `just migrate publish RUN_DIR`; after tablet initialization and sync: `just migrate resume RUN_DIR`.
- Saved migration state: `just migrate status RUN_DIR`.

## Local rules

- Retain the existing Bash scripts and argument handling. The user explicitly declined a CLI rewrite and agent-mode changes.
- The new migration CLI uses Click and supports `AGENT=1`; do not change existing Bash output or parsing as part of that workflow.
- Cloud access uses remarkable CLI 1.2+ for complete native archives, separate PDF uploads, native imports, and tag/viewport transfer. Read `AGENT=1 remarkable skill`; the runner sets `AGENT=1` and `--no-cache` on every cloud command and saves its arguments, output, and exit status.
- Use `--remarkable PATH` or `REMARKABLE_BIN` to select the executable. Report missing required capabilities instead of substituting another client or implementing direct cloud requests.
- The runner accepts remarkable `doc archive` ZIPs with verified snapshot evidence. Manifest version 2 identifies current runs; prepare a fresh run for older manifests while retaining their scripts, backups, maps, and logs.
- Publication saves the CLI's upload evidence and recovers its recorded UUID without creating a second document. Resumption accepts a previously committed import only after exact native-byte verification; settings transfer requires unchanged unrelated destination state.
- Keep migration runs under `.tmp/`; source native archives are never replacement targets. Retain saved manifests and inspect destination state after ambiguous uploads before selecting another action.
- Keep just recipes thin. Use positional arguments and quoted `"$@"` to preserve argument boundaries.
- Resolve build paths relative to the repository, not the caller's working directory.
- Preview paths supplied directly to the script resolve from the caller first, then the repo's `build/` and root. Through just, relative paths start at the repo root.
- An omitted `--standup` must leave the Typst config in control; pass a Typst input only for an explicit override.
- Preserve all six country/weekend variant filenames and both README generated-block markers.
- `build-all.sh` updates README as well as PDFs; verify it in a scratch copy under `.tmp/`.
- `preview.sh` defaults to the 2026 USA batch PDFs. For a custom PDF, supply page specs too; otherwise the built-in PAGES list selects the source PDFs.
- Preview images belong in `preview/`, not beside these scripts. Use `OUT_DIR=.tmp/preview` during verification.
- Use `printf` for multiline help; never heredocs. Put scratch files under `.tmp/`.

See [../AGENTS.md](../AGENTS.md) for shared boundaries. The scripts directory is excluded from the coverage requirement.
