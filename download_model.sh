#!/usr/bin/env bash
# Download EDGE checkpoint from Google Drive.
# The old wget cookie trick fails on large files (returns the virus-scan HTML).
set -euo pipefail

cd "$(dirname "$0")"

FILE_ID="1BAR712cVEqB8GR37fcEihRV_xOC-fZrZ"
OUT="checkpoint.pt"
URL="https://drive.google.com/uc?id=${FILE_ID}"

rm -f "${OUT}"

PYTHON=""
if command -v python >/dev/null 2>&1; then
  PYTHON=python
elif command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
fi

download_with_gdown() {
  if command -v gdown >/dev/null 2>&1; then
    gdown --fuzzy "${URL}" -O "${OUT}"
  elif [[ -n "${PYTHON}" ]] && "${PYTHON}" -c "import gdown" >/dev/null 2>&1; then
    "${PYTHON}" -m gdown --fuzzy "${URL}" -O "${OUT}"
  elif [[ -n "${PYTHON}" ]]; then
    "${PYTHON}" -m pip install -q gdown
    "${PYTHON}" -m gdown --fuzzy "${URL}" -O "${OUT}"
  else
    echo "ERROR: Need gdown or python to download from Google Drive." >&2
    echo "Install with: pip install gdown" >&2
    exit 1
  fi
}

echo "Downloading checkpoint.pt via gdown..."
download_with_gdown

if [[ ! -f "${OUT}" ]]; then
  echo "ERROR: ${OUT} was not created." >&2
  exit 1
fi

size=$(wc -c < "${OUT}")
if [[ "${size}" -lt 1000000 ]]; then
  echo "ERROR: ${OUT} is only ${size} bytes (likely an HTML warning page, not the checkpoint)." >&2
  exit 1
fi

# Reject HTML leftovers from failed Drive downloads
if head -c 15 "${OUT}" | grep -q '<!DOCTYPE\|<html'; then
  echo "ERROR: ${OUT} looks like HTML, not a PyTorch checkpoint." >&2
  exit 1
fi

echo "Done. $(ls -lh "${OUT}")"
