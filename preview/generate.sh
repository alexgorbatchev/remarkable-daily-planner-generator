#!/usr/bin/env bash

# Renders selected pages from the generated PDF into PNGs.
# Output: preview/*.png (file names controlled by page specs)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Edit this list to control which pages get rendered.
#
# Formats:
#   - "N"            -> writes ${OUT_DIR}/page-N.png
#   - "N:NAME"       -> writes ${OUT_DIR}/NAME.png
#   - "N:NAME.png"   -> also supported (the .png suffix is ignored)
#   - "PDF:N:NAME"   -> renders page N from PDF into ${OUT_DIR}/NAME.png
PAGES=(
  "planner-no-weekends-2026.pdf:1:calendar-view--no-weekends"
  "planner-weekends-2026.pdf:1:calendar-view--weekends"
  "planner-no-weekends-2026.pdf:2:day-view"
  "planner-no-weekends-2026.pdf:263:notes-view"
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

DEFAULT_SOURCE_PDF="2026.pdf"

# You can pass the PDF file name (preferred) or a full path as the first arg,
# or set PDF_PATH to override everything.
PDF_PATH="${PDF_PATH:-}"

usage() {
  cat <<'EOF'
Usage:
  ./preview/generate.sh [SOURCE_PDF] [PAGE_SPEC...]

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
    Use "N:NAME" to control the output file name per page.

Args:
  PAGE_SPEC formats:
    - N
    - N:NAME
    - N:NAME.png
    - PDF:N:NAME

Examples:
  ./preview/generate.sh                 # uses build/2026.pdf
  ./preview/generate.sh 2026.pdf
  ./preview/generate.sh build/planner-2026.pdf
  ./preview/generate.sh 2026.pdf 1:calendar 2:jan 263:jan-01-notes
  ./preview/generate.sh 2026.pdf:1:calendar 2026.pdf:2:jan 2026.pdf:263:jan-01-notes
  DPI=300 ./preview/generate.sh 2026.pdf
  SHADOW=true ./preview/generate.sh 2026.pdf
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

is_pagespec() {
  local s="${1}"
  [[ "${s}" =~ ^[0-9]+(:[^/]+)?$ ]] || [[ "${s}" =~ ^[^:]+\.pdf:[0-9]+:[^/]+$ ]]
}

resolve_pdf() {
  local src="${1}"
  if [[ -f "${src}" ]]; then
    echo "${src}"
  elif [[ -f "${ROOT_DIR}/build/${src}" ]]; then
    echo "${ROOT_DIR}/build/${src}"
  elif [[ -f "${ROOT_DIR}/${src}" ]]; then
    echo "${ROOT_DIR}/${src}"
  else
    return 1
  fi
}

PAGE_SPECS=()

if [[ $# -gt 0 ]]; then
  if is_pagespec "${1}"; then
    # First arg is a page spec; use default source PDF.
    PAGE_SPECS=("$@")
  else
    # First arg is a source PDF (name or path). Remaining args are page specs.
    SOURCE_PDF_ARG="${1}"
    shift
    if [[ $# -gt 0 ]]; then
      PAGE_SPECS=("$@")
    fi
  fi
fi

if [[ -z "${PDF_PATH}" ]]; then
  SOURCE_PDF="${SOURCE_PDF_ARG:-${DEFAULT_SOURCE_PDF}}"

  if ! PDF_PATH="$(resolve_pdf "${SOURCE_PDF}")"; then
    die "PDF not found: ${SOURCE_PDF} (looked in '.', './build', and repo root)"
  fi
fi

[[ -f "${PDF_PATH}" ]] || die "PDF not found: ${PDF_PATH}"

mkdir -p "${OUT_DIR}"

have_pdftoppm=false
have_magick=false

command -v pdftoppm >/dev/null 2>&1 && have_pdftoppm=true
command -v magick >/dev/null 2>&1 && have_magick=true

if [[ "${have_pdftoppm}" != "true" && "${have_magick}" != "true" ]]; then
  die "Missing dependency: install 'pdftoppm' (poppler) or 'magick' (ImageMagick)"
fi

echo "Rendering pages to ${OUT_DIR}/*.png"
echo "  Default PDF: ${PDF_PATH}"
echo "  DPI: ${DPI}"
echo "  Shadow: ${SHADOW}"

default_renderer=""
if [[ "${have_pdftoppm}" == "true" ]]; then
  default_renderer="pdftoppm"
else
  default_renderer="magick"
fi

echo "  Renderer: ${default_renderer}"

items=("${PAGES[@]}")
if [[ ${#PAGE_SPECS[@]} -gt 0 ]]; then
  items=("${PAGE_SPECS[@]}")
fi

for page in "${items[@]}"; do
  item="${page}"
  page_num=""
  out_name=""
  item_pdf="${PDF_PATH}"

  if [[ "${item}" =~ ^[^:]+\.pdf:[0-9]+:.*$ ]]; then
    pdf_src="${item%%:*}"
    rest="${item#*:}"
    page_num="${rest%%:*}"
    out_name="${rest#*:}"

    if ! item_pdf="$(resolve_pdf "${pdf_src}")"; then
      die "PDF not found: ${pdf_src} (from spec '${item}')"
    fi
  elif [[ "${item}" == *:* ]]; then
    page_num="${item%%:*}"
    out_name="${item#*:}"
  else
    page_num="${item}"
    out_name="page-${page_num}"
  fi

  [[ "${page_num}" =~ ^[0-9]+$ ]] || die "Invalid page number in PAGES: '${item}'"
  [[ "${page_num}" -ge 1 ]] || die "Invalid page number in PAGES: '${item}'"
  [[ -n "${out_name}" ]] || die "Missing output name in PAGES entry: '${item}'"
  [[ "${out_name}" != *"/"* ]] || die "Output name must be a file name (no '/'): '${out_name}'"

  out_name="${out_name%.png}"
  out_prefix="${OUT_DIR}/${out_name}"
  out_file="${out_prefix}.png"
  tmp_file="${out_prefix}.tmp.png"

  echo "- page ${page_num} -> ${out_file} (from $(basename "${item_pdf}"))"

  if [[ "${default_renderer}" == "pdftoppm" ]]; then
    # Produces ${out_prefix}.png
    pdftoppm -f "${page_num}" -l "${page_num}" -r "${DPI}" -png -singlefile "${item_pdf}" "${out_prefix}"

    # Normalize into an opaque, white-backed page image first.
    if [[ "${have_magick}" == "true" ]]; then
      magick "${out_file}" -background white -alpha remove -alpha off -quality 95 "${tmp_file}"
    else
      mv -f "${out_file}" "${tmp_file}"
    fi
  else
    # ImageMagick uses zero-based page index.
    magick -density "${DPI}" "${item_pdf}[$((page_num - 1))]" -background white -alpha remove -alpha off -quality 95 "${tmp_file}"
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
