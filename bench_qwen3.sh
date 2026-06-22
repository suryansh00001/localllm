#!/bin/bash
set -e

MODEL_ID="bartowski/Qwen_Qwen3.6-35B-A3B-GGUF"
QUANT="Q4_K_M"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="${SCRIPT_DIR}"
MODEL_FILE="Qwen_Qwen3.6-35B-A3B-${QUANT}.gguf"
MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"

mkdir -p "${MODEL_DIR}"

if [ ! -f "${MODEL_PATH}" ]; then
    echo "Downloading ${MODEL_FILE}..."
    hf download "${MODEL_ID}" "${MODEL_FILE}" --local-dir "${MODEL_DIR}"
    echo "Download complete."
else
    echo "Model already exists at ${MODEL_PATH}, skipping download."
fi

echo "Running llama-bench (sweeping --n-cpu-moe and prompt sizes)..."

llama-bench \
    -m "${MODEL_PATH}" \
    --cache-type-k turbo3 \
    --cache-type-v turbo3 \
    --n-gpu-layers 999 \
    --n-cpu-moe 41 \
    --flash-attn on \
    -p 0 \
    -d 512,2048,8192,32768,131072,262144 \
    -n 128 \
    --progress;
