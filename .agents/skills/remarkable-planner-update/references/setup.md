# Native migration dependencies

Run from the planner repository root. `just migration-setup` installs the pinned
Click, pypdf, and PyMuPDF dependencies into the existing project-local `.venv`,
creating that environment only when it is absent. Python commands run through uv.
Typst is required for replacement backgrounds. Use remarkable CLI 1.2.1 or newer
for cloud migrations. Version 1.2.0 has short HTTP request deadlines
that interrupted the exercised native transfer; 1.2.1 adds bounded immutable-blob
recovery while retaining command deadlines and single-attempt root commits.
Read its embedded skill before operational commands:

```bash
AGENT=1 remarkable skill
AGENT=1 remarkable --version
```

```bash
just migration-setup
just migrate --help
just migration-test
```

Reuse existing remarkable authentication; never print credentials or pair without
a registration code from the user. Select the executable with `--remarkable PATH`
on preparation or `REMARKABLE_BIN`; it is saved with the run. The runner sets
`AGENT=1` and `--no-cache` on every invocation. Local `prepare --source-archive`,
`status`, and tests do not access the cloud. See [cloud transfer](cloud.md).

Offline inputs must be complete remarkable `doc archive` ZIPs containing
`files/`, `evidence/snapshot.json`, and `evidence/document.docSchema`. Every native
file is checked against the snapshot hashes and sizes. Older client archives and
version-1 run manifests are unsupported; preserve them and prepare a fresh run
from remarkable. Current manifests use version 2.

The background assembler remains in `scripts/assemble.py` within this skill.
Its tests can be run with:

```bash
uv run --python .venv/bin/python python -m unittest discover -s .agents/skills/remarkable-planner-update/scripts -p 'test_*.py'
```

Official references: [Click](https://click.palletsprojects.com/en/stable/),
[pypdf](https://pypdf.readthedocs.io/en/stable/user/merging-pdfs.html),
[Typst JSON](https://typst.app/docs/reference/data-loading/json/), and
[remarkable CLI](https://github.com/alexgorbatchev/remarkable-cli).
