#!/usr/bin/env bash
# Fetch the docling.rs OCR models the app bundles as Flutter assets.
#
# Source: https://github.com/docling-project/docling.rs/releases (tag models-v1),
# verified against the release's SHA256SUMS. ~31 MB in total:
#   ocr_det.onnx          PP-OCRv6 text detector
#   ocr_rec_v6.onnx       PP-OCRv6 multilingual recognizer (+ dictionary)
#   ocr_textline_ori.onnx 0/180° text-line orientation classifier (optional)
#
# Usage: scripts/download_models.sh [target-dir]   (default: app/assets/models)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$ROOT/app/assets/models}"
BASE="${DOCLING_RS_MODELS_URL:-https://github.com/docling-project/docling.rs/releases/download/models-v1}"
FILES=(ocr_det.onnx ocr_rec_v6.onnx ocr_rec_v6_dict.txt ocr_textline_ori.onnx)

mkdir -p "$TARGET"
cd "$TARGET"
curl -fsSL -o SHA256SUMS "$BASE/SHA256SUMS"
for f in "${FILES[@]}"; do
  if [ -f "$f" ] && grep -E "  $f\$" SHA256SUMS | sha256sum -c --quiet - 2>/dev/null; then
    echo "ok (cached)  $f"
    continue
  fi
  echo "downloading  $f"
  curl -fsSL -o "$f" "$BASE/$f"
  grep -E "  $f\$" SHA256SUMS | sha256sum -c --quiet -
done
echo "models-v1 $(date -u +%Y-%m-%d)" > VERSION
rm -f SHA256SUMS
echo "models in $TARGET"
