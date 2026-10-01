# Native migration dependencies

Run from the planner repository root. `just migration-setup` installs the pinned
Click, pypdf, and PyMuPDF dependencies into the existing project-local `.venv`,
creating that environment only when it is absent. Python commands run through uv.
Typst is required for replacement backgrounds. Use the installed `remarkable`
CLI for cloud access; read its embedded skill before operational commands:

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
a registration code from the user. The runner's cloud paths are not integrated
with remarkable yet. Do not invoke `prepare --source`, `publish`, or `resume`;
local `prepare --source-archive`, `status`, and tests do not access the cloud.
See [cloud transfer](cloud.md) for supported imports and missing operations.

The background assembler remains in `scripts/assemble.py` within this skill.
Its tests can be run with:

```bash
uv run --python .venv/bin/python python -m unittest discover -s .agents/skills/remarkable-planner-update/scripts -p 'test_*.py'
```

Official references: [Click](https://click.palletsprojects.com/en/stable/),
[pypdf](https://pypdf.readthedocs.io/en/stable/user/merging-pdfs.html),
[Typst JSON](https://typst.app/docs/reference/data-loading/json/), and
[remarkable CLI](https://github.com/alexgorbatchev/remarkable-cli).
