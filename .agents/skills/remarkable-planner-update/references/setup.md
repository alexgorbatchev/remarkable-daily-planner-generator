# Local dependencies

Run from the planner repository root. Use `.tmp/` for intermediate files and
`output/pdf/` for final artifacts; choose unused paths for each migration.

- Typst generates replacement templates; Poppler supplies `pdfinfo`, `pdftotext`,
  and `pdftoppm` for inspection.
- `remarkable` downloads and renders documents and exports local `.rm` strokes.
  Check live `--help`; do not assume an upload subcommand exists.
- Python uses a project-root `.venv` through `uv`. Do not install globally.

```bash
# Create .venv only when absent; preserve any existing environment.
uv venv
uv pip install pypdf cairosvg
```

The assembly helper is exercised with pypdf 6.19.0. Vector conversion is exercised
with CairoSVG 2.9.1. Inspect installed versions and current APIs before adapting it.
For example, current `compress_identical_objects()` uses `remove_duplicates` and
`remove_unreferenced`; its older parameter names are deprecated.

On macOS, CairoSVG may fail to discover an installed Cairo library. Check the
actual library location. If using Homebrew, obtain its prefix with
`brew --prefix cairo`. Set `DYLD_FALLBACK_LIBRARY_PATH` inside the Python process
**before importing CairoSVG**, using that discovered prefix plus `/lib`, while
preserving existing search paths. A shell wrapper can strip `DYLD_*` environment
variables before launching Python. Do not hardcode a machine-specific prefix.

## Check the helper

```bash
PYTHONDONTWRITEBYTECODE=1 uv run python -m unittest discover \
  -s .agents/skills/remarkable-planner-update/scripts -p 'test_*.py'
```

Import `assemble.py` from a task-specific Python driver. It deliberately has no
argument parser or cloud operations. Its input/output contract is documented in
the function docstring and the assembly reference.

## Official references

- [pypdf merging and object cloning](https://pypdf.readthedocs.io/en/stable/user/merging-pdfs.html)
- [pypdf page methods](https://pypdf.readthedocs.io/en/stable/modules/PageObject.html)
- [pypdf writer methods](https://pypdf.readthedocs.io/en/stable/modules/PdfWriter.html)
- [CairoSVG conversion API](https://cairosvg.org/documentation/)
- [remarkable CLI](https://github.com/alexgorbatchev/remarkable-cli)
- [maintained rmapi](https://github.com/ddvk/rmapi)
