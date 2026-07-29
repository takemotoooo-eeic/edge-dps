#!/usr/bin/env bash
# Download AIST++ wavs + motions from Google Drive.
# The old wget cookie trick fails on large files (returns the virus-scan HTML).
set -euo pipefail

cd "$(dirname "$0")"

FILE_ID="1RzqSbSnbMEwLUagV0GThfpm9JJXePGkV"
OUT="edge_aistpp.zip"
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

echo "Downloading edge_aistpp.zip via gdown..."
download_with_gdown

# Guard against HTML / incomplete downloads
if [[ ! -f "${OUT}" ]]; then
  echo "ERROR: ${OUT} was not created." >&2
  exit 1
fi

size=$(wc -c < "${OUT}")
if [[ "${size}" -lt 1000000 ]]; then
  echo "ERROR: ${OUT} is only ${size} bytes (likely an HTML warning page, not the dataset)." >&2
  exit 1
fi

if ! unzip -t "${OUT}" >/dev/null; then
  echo "ERROR: ${OUT} is not a valid zip archive." >&2
  exit 1
fi

echo "Extracting ${OUT}..."
unzip -o "${OUT}"
echo "Done."
