#!/bin/bash

# Build script for Daily Planner
# Compiles the Typst document and generates the PDF

set -euo pipefail  # Exit on any error, undefined variables, pipe failures

echo "Building Daily Planner..."

# Compile the main document
typst compile index.typ

echo "✓ Build successful! Generated index.pdf"

# Show file size and page count
if command -v mdls &> /dev/null; then
    pages=$(mdls -name kMDItemNumberOfPages index.pdf 2>/dev/null | grep -o '[0-9]*' || echo "unknown")
    echo "  Pages: ${pages}"
fi

if command -v stat &> /dev/null && command -v numfmt &> /dev/null; then
    size=$(stat -f%z index.pdf 2>/dev/null | numfmt --to=iec)
else
    size=$(ls -lh index.pdf | awk '{print $5}')
fi
echo "  Size: ${size}"

# Optional: Open the PDF (uncomment if desired)
# open index.pdf