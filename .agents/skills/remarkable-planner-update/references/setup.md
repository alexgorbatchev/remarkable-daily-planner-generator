# Native migration dependencies

Run from the planner repository root. `just migration-setup` installs the pinned
Click, pypdf, and PyMuPDF dependencies into the existing project-local `.venv`,
creating that environment only when it is absent. Python commands run through uv.
Typst is required for replacement backgrounds; rmapi is required for cloud steps.

```bash
just migration-setup
just migrate --help
just migration-test
```

Use the maintained `ddvk/rmapi` client. The working flow was exercised with v0.0.35.
Reuse its existing authentication. Set `RMAPI_BIN` to the executable, or pass
`--rmapi PATH` during preparation; the run saves that choice. The runner does not
install or pair a client, print credentials, or modify the remarkable CLI.

The background assembler remains in `scripts/assemble.py` within this skill.
Its tests can be run with:

```bash
uv run --python .venv/bin/python python -m unittest discover -s .agents/skills/remarkable-planner-update/scripts -p 'test_*.py'
```

Official references: [Click](https://click.palletsprojects.com/en/stable/),
[pypdf](https://pypdf.readthedocs.io/en/stable/user/merging-pdfs.html),
[Typst JSON](https://typst.app/docs/reference/data-loading/json/), and
[rmapi](https://github.com/ddvk/rmapi).
