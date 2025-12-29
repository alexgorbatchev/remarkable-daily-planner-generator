#!/usr/bin/env bash

# Renders selected pages from the generated PDF into PNGs.
# Output: preview/page-[num].png

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Edit this list to control which pages get rendered.
PAGES=(
  1
  2
  263
)

OUT_DIR="${OUT_DIR:-${SCRIPT_DIR}}"
DPI="${DPI:-200}"

# Optional: add a blurred shadow around the page on a transparent background.
# When enabled, output PNGs will have an alpha channel (transparent outside the page + shadow).
SHADOW="${SHADOW:-true}"
SHADOW_OPACITY="${SHADOW_OPACITY:-35}"  # 0..100
SHADOW_BLUR="${SHADOW_BLUR:-14}"
SHADOW_X="${SHADOW_X:-0}"
SHADOW_Y="${SHADOW_Y:-10}"
SHADOW_PAD="${SHADOW_PAD:-24}"          # pixels of transparent padding around page before shadow

# You can pass the PDF path as the first arg, or set PDF_PATH.
PDF_PATH="${PDF_PATH:-${1:-${ROOT_DIR}/build/planner-2026.pdf}}"

usage() {
  cat <<'EOF'
Usage:
  ./preview/generate.sh [PDF_PATH]

Environment:
  PDF_PATH=...       (optional, overrides arg)
  OUT_DIR=...        (optional, defaults to ./preview)
  DPI=200            (optional)
  SHADOW=true        (optional, true|false)
  SHADOW_OPACITY=35  (optional, 0..100)
  SHADOW_BLUR=14     (optional)
  SHADOW_X=0         (optional)
  SHADOW_Y=10        (optional)
  SHADOW_PAD=24      (optional, pixels)

Edits:
  - Set PAGES=(...) inside the script.

Examples:
  ./preview/generate.sh build/planner-2026.pdf
  DPI=300 ./preview/generate.sh build/planner-2026.pdf
  SHADOW=true ./preview/generate.sh build/planner-2026.pdf
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

[[ -f "${PDF_PATH}" ]] || die "PDF not found: ${PDF_PATH}"

mkdir -p "${OUT_DIR}"

have_pdftoppm=false
have_magick=false

command -v pdftoppm >/dev/null 2>&1 && have_pdftoppm=true
command -v magick >/dev/null 2>&1 && have_magick=true

if [[ "${have_pdftoppm}" != "true" && "${have_magick}" != "true" ]]; then
  die "Missing dependency: install 'pdftoppm' (poppler) or 'magick' (ImageMagick)"
fi

echo "Rendering pages to ${OUT_DIR}/page-[num].png"
echo "  PDF: ${PDF_PATH}"
echo "  DPI: ${DPI}"
echo "  Shadow: ${SHADOW}"

default_renderer=""
if [[ "${have_pdftoppm}" == "true" ]]; then
  default_renderer="pdftoppm"
else
  default_renderer="magick"
fi

echo "  Renderer: ${default_renderer}"

for page in "${PAGES[@]}"; do
  [[ "${page}" =~ ^[0-9]+$ ]] || die "Invalid page number in PAGES: '${page}'"
  [[ "${page}" -ge 1 ]] || die "Invalid page number in PAGES: '${page}'"

  out_prefix="${OUT_DIR}/page-${page}"
  out_file="${out_prefix}.png"
  tmp_file="${out_prefix}.tmp.png"

  echo "- page ${page} -> ${out_file}"

  if [[ "${default_renderer}" == "pdftoppm" ]]; then
    # Produces ${out_prefix}.png
    pdftoppm -f "${page}" -l "${page}" -r "${DPI}" -png -singlefile "${PDF_PATH}" "${out_prefix}"

    # Normalize into an opaque, white-backed page image first.
    if [[ "${have_magick}" == "true" ]]; then
      magick "${out_file}" -background white -alpha remove -alpha off -quality 95 "${tmp_file}"
    else
      mv -f "${out_file}" "${tmp_file}"
    fi
  else
    # ImageMagick uses zero-based page index.
    magick -density "${DPI}" "${PDF_PATH}[$((page - 1))]" -background white -alpha remove -alpha off -quality 95 "${tmp_file}"
  fi

  if [[ "${SHADOW}" == "true" ]]; then
    [[ "${have_magick}" == "true" ]] || die "SHADOW=true requires ImageMagick (magick)"

    # Build a blurred drop shadow from the page rectangle and keep everything else transparent.
    # Result: opaque white page, blurred shadow, transparent background.
    magick "${tmp_file}" \
      -alpha set \
      -bordercolor none -border "${SHADOW_PAD}" \
      \( +clone -background none -shadow "${SHADOW_OPACITY}x${SHADOW_BLUR}+${SHADOW_X}+${SHADOW_Y}" \) \
      +swap -background none -layers merge +repage \
      "${out_file}"
    rm -f "${tmp_file}"
  else
    mv -f "${tmp_file}" "${out_file}"
  fi
done

echo "Done."
