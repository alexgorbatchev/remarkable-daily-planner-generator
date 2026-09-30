set positional-arguments

# List available commands.
default:
    @just --list

# Build a planner, e.g. just build 2026 --standup --open.
build *args:
    bash scripts/build.sh "$@"

alias run := build

# Build all country/weekend variants and update README download links.
build-all *args:
    bash scripts/build-all.sh "$@"

# Render preview PNGs; use --help for page specs and environment options.
preview *args:
    bash scripts/preview.sh "$@"

# Check shell syntax.
lint:
    @for script in scripts/*.sh; do bash -n "$script" || exit; done

# Smoke-compile planners with standups off and on without replacing build PDFs.
test:
    mkdir -p .tmp
    typst compile --root . --input year=2026 --input standup=false src/index.typ .tmp/planner-test.pdf
    typst compile --root . --input year=2026 --input standup=true src/index.typ .tmp/planner-standup-test.pdf

# Check shell syntax and compile both planner configurations.
check: lint test
