---
created_on: 2026-09-29 20:19
last_modified: 2026-09-29 20:19
status: current
---

# Build and preview scripts

Bash scripts build Typst PDFs and render preview images; the root justfile forwards arguments.

## Commands

- Syntax check: `just lint`
- Planner options: `just build --help`
- Batch options: `just build-all --help`
- Preview options: `just preview --help`
- Compile smoke checks: `just test`

## Local rules

- Retain the existing Bash scripts and argument handling. The user explicitly declined a CLI rewrite and agent-mode changes.
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
