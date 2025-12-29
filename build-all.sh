#!/usr/bin/env bash

set -euo pipefail
set +H 2>/dev/null || true

usage() {
  cat <<'EOF'
Usage:
  ./build-all.sh YEAR

Examples:
  ./build-all.sh 2026
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

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

[[ -n "${YEAR}" ]] || { usage >&2; exit 2; }
[[ "${YEAR}" =~ ^[0-9]{4}$ ]] || die "YEAR must be a 4-digit number (e.g. 2026)"
# Deps check (after args)
command -v typst &> /dev/null || die "Missing dependency: typst (https://typst.app)"

OUTPUT_DIR="build"

# Variant definitions live here, and everything else derives from this.
# Format matches VARIANT_WEEKENDS: "value/input|slug|label"
# - value/input: passed to Typst via `--input ...=...`
# - slug: used in output filenames (stable, URL/file friendly)
# - label: human-readable text used in README link labels
VARIANT_COUNTRIES=(
  "usa|usa|USA"
  "ca-on|canada-ontario|Canada Ontario"
)

# Weekend variants (2 PDFs per country):
# - value/input: passed to Typst as `--input weekends=true|false`
# - slug: filename component (e.g. planner-no-weekends-...)
# - label: README text (e.g. "No weekends")
VARIANT_WEEKENDS=(
  "false|no-weekends|No weekends"
  "true|weekends|Weekends"
)

variant_out_path() {
  local year="$1"
  local country_slug="$2"
  local weekends_slug="$3"

  echo "${OUTPUT_DIR}/planner-${weekends_slug}-${country_slug}-${year}.pdf"
}

update_readme() {
  local year="$1"
  local readme="README.md"

  [[ -f "${readme}" ]] || die "README.md not found (run from repo root)"
  grep -q '<!-- generated -->' "${readme}" || die "README.md missing <!-- generated --> marker"
  grep -q '<!-- /generated -->' "${readme}" || die "README.md missing <!-- /generated --> marker"

  local tmp
  tmp="${readme}.tmp.$$"

  local block_tmp
  block_tmp="${readme}.generated.$$"

  # Build the generated block from the same variant definitions.
  : > "${block_tmp}"
  for entry in "${VARIANT_COUNTRIES[@]}"; do
    IFS='|' read -r country_input country_slug label <<<"${entry}" || true
    for w in "${VARIANT_WEEKENDS[@]}"; do
      IFS='|' read -r weekends_value weekends_slug weekends_label <<<"${w}" || true
      out_path="$(variant_out_path "${year}" "${country_slug}" "${weekends_slug}")"
      printf '%s\n' "- **[${year}, ${label}, ${weekends_label}](${out_path})**" >> "${block_tmp}"
    done
  done

  awk -v year="${year}" -v block_file="${block_tmp}" '
    BEGIN {
      in_block = 0
      replaced = 0
    }
    $0 ~ /<!--[[:space:]]*generated[[:space:]]*-->/ {
      print $0
      while ((getline line < block_file) > 0) {
        print line
      }
      close(block_file)
      print "<!-- /generated -->"
      in_block = 1
      replaced = 1
      next
    }
    $0 ~ /<!--[[:space:]]*\/generated[[:space:]]*-->/ {
      if (in_block == 1) {
        in_block = 0
        next
      }
    }
    in_block == 1 { next }
    { print }
    END {
      if (replaced != 1) {
        exit 2
      }
    }
  ' "${readme}" > "${tmp}" || {
    rc=$?
    rm -f "${tmp}"
    rm -f "${block_tmp}"
    if [[ $rc -eq 2 ]]; then
      die "Failed to update README.md generated block (marker not found)"
    fi
    die "Failed to update README.md"
  }

  mv -f "${tmp}" "${readme}"
  rm -f "${block_tmp}"
  echo "✓ Updated README.md download links"
}

build_variant() {
  local country="$1"
  local weekends="$2"  # true|false
  local out="$3"

  typst compile \
    --input year="${YEAR}" \
    --input weekends="${weekends}" \
    --input country="${country}" \
    index.typ "${out}"

  echo "✓ ${out}"
}

mkdir -p "${OUTPUT_DIR}"

echo "Building planners for ${YEAR}"

for entry in "${VARIANT_COUNTRIES[@]}"; do
  IFS='|' read -r country_input country_slug _label <<<"${entry}" || true
  for w in "${VARIANT_WEEKENDS[@]}"; do
    IFS='|' read -r weekends_value weekends_slug _weekends_label <<<"${w}" || true
    out="$(variant_out_path "${YEAR}" "${country_slug}" "${weekends_slug}")"
    build_variant "${country_input}" "${weekends_value}" "${out}"
  done
done

update_readme "${YEAR}"

echo "✓ Done"
