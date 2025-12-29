#!/bin/bash

# Dev script for Daily Planner
# Watches the Typst document and regenerates the PDF on changes

set -euo pipefail  # Exit on any error, undefined variables, pipe failures

usage() {
    cat <<'EOF'
Usage:
    ./dev.sh [YEAR]
    ./dev.sh --year YEAR

Examples:
    ./dev.sh            # defaults to 2026
    ./dev.sh 2026
    ./dev.sh --year 2026
EOF
}

die() {
    echo "Error: $*" >&2
    exit 1
}

DEFAULT_YEAR="2026"
YEAR=""

# Args check first
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -y|--year)
            shift
            [[ $# -gt 0 ]] || die "--year requires a value"
            YEAR="$1"
            shift
            ;;
        --)
            shift
            break
            ;;
        -* )
            die "Unknown option: $1"
            ;;
        * )
            if [[ -z "${YEAR}" ]]; then
                YEAR="$1"
                shift
            else
                die "Unexpected argument: $1"
            fi
            ;;
    esac
done

if [[ -z "${YEAR}" ]]; then
    YEAR="${DEFAULT_YEAR}"
fi
[[ "${YEAR}" =~ ^[0-9]{4}$ ]] || die "YEAR must be a 4-digit number (e.g. 2026)"

echo "Watching Daily Planner..."

# Deps check (after args)
command -v typst &> /dev/null || die "Missing dependency: typst (https://typst.app)"

OUTPUT_DIR="build"
OUTPUT_PDF="planner-${YEAR}.pdf"
OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT_PDF}"

mkdir -p "${OUTPUT_DIR}"

echo "  Output: ${OUTPUT_PATH}"
echo "  Press Ctrl-C to stop"

# Watch the main document
typst watch --input year="${YEAR}" index.typ "${OUTPUT_PATH}"