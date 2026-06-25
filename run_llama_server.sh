#!/bin/bash
set -e

MODEL_ID="bartowski/Qwen_Qwen3.6-35B-A3B-GGUF"
QUANT="Q3_K_M"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="${SCRIPT_DIR}"
MODEL_FILE="Qwen_Qwen3.6-35B-A3B-${QUANT}.gguf"
MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"
PORT=8080
HOST="0.0.0.0"

mkdir -p "${MODEL_DIR}"

if [ ! -f "${MODEL_PATH}" ]; then
    echo "Downloading ${MODEL_FILE}..."
    hf download "${MODEL_ID}" "${MODEL_FILE}" --local-dir "${MODEL_DIR}"
    echo "Download complete."
else
    echo "Model already exists at ${MODEL_PATH}, skipping download."
fi

echo "Starting llama-server on ${HOST}:${PORT}..."
echo "API endpoint: http://localhost:${PORT}/v1"

llama-server \
    --model "${MODEL_PATH}" \
    --port "${PORT}" \
    --host "${HOST}" \
    --ctx-size 262144 \
    --cache-type-k turbo3 \
    --cache-type-v turbo3 \
    --n-gpu-layers 999 \
    --n-cpu-moe 41 \
    --reasoning on \
    --reasoning-format deepseek \
    --reasoning-budget -1 \
    --parallel 1 \
	--flash-attn on;
