#!/bin/bash
set -e

MODEL_ID="bartowski/Qwen_Qwen3.6-35B-A3B-GGUF"
QUANT="Q3_K_M"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_FILE="Qwen_Qwen3.6-35B-A3B-${QUANT}.gguf"
MODEL_PATH="${SCRIPT_DIR}/${MODEL_FILE}"

if [ -f "${MODEL_PATH}" ]; then
    echo "Model already exists at ${MODEL_PATH}, skipping download."
    exit 0
fi

echo "Downloading ${MODEL_FILE}..."
hf download "${MODEL_ID}" "${MODEL_FILE}" --local-dir "${SCRIPT_DIR}"
echo "Download complete."
