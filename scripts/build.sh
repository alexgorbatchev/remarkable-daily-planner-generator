#!/bin/bash

# Build script for Daily Planner
# Compiles the Typst document and generates the PDF

set -euo pipefail  # Exit on any error, undefined variables, pipe failures

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

usage() {
  printf '%s\n' \
    'Usage:' \
    '  just build YEAR [OPTIONS]' \
    '  scripts/build.sh --year YEAR [OPTIONS]' \
    '' \
    'Options:' \
    '  --weekends=true|false   Include weekends (default: false)' \
    '  --country=COUNTRY       Special dates country (default: usa)' \
    '  --standup               Include daily standup pages' \
    '  --standup=true|false    Override STANDUP.enabled from config' \
    '  --open                  Open the generated PDF' \
    '  --watch                 Rebuild when source files change' \
    '' \
    'Without --standup, the build uses STANDUP.enabled from config.' \
    '' \
    'Examples:' \
    '  just build 2026' \
    '  just build 2026 --standup --open' \
    '  just build 2026 --standup=false' \
    '  just build 2026 --standup --watch'
}

die() {
  echo "Error: $*" >&2
  exit 1
}

YEAR=""
WEEKENDS="false"
COUNTRY="usa"
OPEN="false"
WATCH="false"
STANDUP=""

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
    --weekends)
      shift
      [[ $# -gt 0 ]] || die "--weekends requires a value (true|false)"
      WEEKENDS="$1"
      shift
      ;;
    --weekends=*)
      WEEKENDS="${1#--weekends=}"
      shift
      ;;
    --country)
      shift
      [[ $# -gt 0 ]] || die "--country requires a value (e.g. usa)"
      COUNTRY="$1"
      shift
      ;;
    --country=*)
      COUNTRY="${1#--country=}"
      shift
      ;;
    --standup)
      STANDUP="true"
      shift
      ;;
    --standup=*)
      STANDUP="${1#--standup=}"
      [[ "${STANDUP}" == "true" || "${STANDUP}" == "false" ]] || die "--standup requires true or false"
      shift
      ;;
    --open)
      OPEN="true"
      shift
      ;;
    --watch)
      WATCH="true"
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

[[ -n "${YEAR}" ]] || { usage >&2; exit 2; }
[[ "${YEAR}" =~ ^[0-9]{4}$ ]] || die "YEAR must be a 4-digit number (e.g. 2026)"

TYPST_INPUTS=(--root . --input "year=${YEAR}" --input "weekends=${WEEKENDS}" --input "country=${COUNTRY}")
if [[ -n "${STANDUP}" ]]; then
  TYPST_INPUTS+=(--input "standup=${STANDUP}")
fi

echo "Building Daily Planner..."

# Deps check (after args)
command -v typst &> /dev/null || die "Missing dependency: typst (https://typst.app)"

OUTPUT_DIR="build"
OUTPUT_PDF="planner-${YEAR}.pdf"
OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT_PDF}"

mkdir -p "${OUTPUT_DIR}"

if [[ "${WATCH}" == "true" ]]; then
  echo "Watching Daily Planner..."
  echo "  Output: ${OUTPUT_PATH}"
  echo "  Press Ctrl-C to stop"

  if [[ "${OPEN}" == "true" ]]; then
    command -v open &> /dev/null || die "Missing dependency: open (macOS)"
    typst compile "${TYPST_INPUTS[@]}" src/index.typ "${OUTPUT_PATH}"
    open "${OUTPUT_PATH}"
  fi

  typst watch "${TYPST_INPUTS[@]}" src/index.typ "${OUTPUT_PATH}"
else
  # Compile the main document
  typst compile "${TYPST_INPUTS[@]}" src/index.typ "${OUTPUT_PATH}"

  echo "✓ Build successful!"
  echo "  Generated ${OUTPUT_PATH}"

  # Show file size and page count
  if command -v mdls &> /dev/null; then
    pages=$(mdls -name kMDItemNumberOfPages "${OUTPUT_PATH}" 2>/dev/null | rg -o '[0-9]+' | head -n 1 || echo "unknown")
    echo "  Pages: ${pages}"
  fi

  if command -v stat &> /dev/null && command -v numfmt &> /dev/null; then
    size=$(stat -f%z "${OUTPUT_PATH}" 2>/dev/null | numfmt --to=iec)
  else
    size=$(ls -lh "${OUTPUT_PATH}" | awk '{print $5}')
  fi
  echo "  Size: ${size}"

  if [[ "${OPEN}" == "true" ]]; then
    command -v open &> /dev/null || die "Missing dependency: open (macOS)"
    open "${OUTPUT_PATH}"
  fi
fi
