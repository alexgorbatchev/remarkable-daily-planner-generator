set positional-arguments

# List available commands.
default:
    @just --list

# Build a planner, e.g. just build 2026 --standup --open.
build *args:
    bash scripts/build.sh "$@"

alias run := build

# Prepare, publish, and resume native planner migrations.
migrate *args:
    uv run --python .venv/bin/python python scripts/migrate.py migration "$@"

# Native migration commands with compact agent output.
run-ai *args:
    AGENT=1 uv run --python .venv/bin/python python scripts/migrate.py "$@"

# Install migration dependencies into the project-local Python environment.
migration-setup:
    if [ ! -x .venv/bin/python ]; then uv venv .venv; fi
    uv pip install --python .venv/bin/python -r scripts/migration/requirements.txt

# Check native copying, page planning, and resumable cloud transitions locally.
migration-test:
    PYTHONPATH=scripts uv run --python .venv/bin/python python -m unittest discover -s scripts/migration -p 'test_*.py'

# Build all country/weekend variants and update README download links.
build-all *args:
    bash scripts/build-all.sh "$@"

# Render preview PNGs; use --help for page specs and environment options.
preview *args:
    bash scripts/preview.sh "$@"

# Check shell syntax.
lint:
    @for script in scripts/*.sh; do bash -n "$script" || exit; done

# Check navigation and smoke-compile both standup settings without replacing build PDFs.
test:
    mkdir -p .tmp
    typst compile --root . --input standup=false tests/navigation.typ .tmp/navigation-test.pdf
    typst compile --root . --input standup=true tests/navigation.typ .tmp/navigation-standup-test.pdf
    typst compile --root . --input year=2026 --input standup=false src/index.typ .tmp/planner-test.pdf
    typst compile --root . --input year=2026 --input standup=true src/index.typ .tmp/planner-standup-test.pdf
    typst compile --root . --input year=2026 --input standup=true --input preset=blue tests/render.typ .tmp/planner-config-blue.pdf
    typst compile --root . --input year=2026 --input standup=true --input preset=underline tests/render.typ .tmp/planner-config-underline.pdf
    typst compile --root . --input year=2026 --input standup=true --input preset=plain tests/render.typ .tmp/planner-config-plain.pdf
    just migration-test

# Check shell syntax and compile both planner configurations.
check: lint test
