# Local LLM Setup — Qwen3.6-35B-A3B

Run a powerful, efficient large language model locally on your machine using [llama.cpp](https://github.com/ggml-org/llama.cpp) with TurboQuant optimizations and Open WebUI.

## 🧠 The Model: Qwen3.6-35B-A3B

| Property | Value |
|---|---|
| **Architecture** | Qwen3.6 MoE (Mixture of Experts) |
| **Total Parameters** | ~35B |
| **Active Parameters** | ~3.3B per forward pass |
| **Quantization** | Q4_K_M |
| **Source** | [bartowski/Qwen_Qwen3.6-35B-A3B-GGUF](https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF) on Hugging Face |

### Why Qwen3.6-35B-A3B?

This model uses a **Mixture of Experts (MoE)** architecture — out of its 35 billion total parameters, only about 3.3 billion are activated per token. This gives you:

- **Massively reduced memory footprint** — a 4-bit quantized MoE model fits in ~5GB VRAM vs ~18GB for a dense 35B model at the same precision
- **Faster inference** — fewer active parameters means faster per-token generation
- **Still excellent quality** — at 35B total parameters, this model punches well above its active-parameter weight, competing with dense models 2–3× its size
- **Better CPU fallback** — the `--n-cpu-moe 41` flag keeps the MoE expert weights on CPU, so even with limited GPU memory you get smooth performance

In short: MoE is the smartest way to run a large model on consumer hardware. You get near-flagship quality without needing a datacenter GPU.

---

## 📜 Scripts

### `download_qwen3.sh` — Download the model only

Downloads the Qwen3.6-35B-A3B GGUF model file (~5GB) from Hugging Face and saves it in the project directory.

**When to use:** If you want to download the model separately (e.g., on a different machine, or to avoid waiting during server startup).

```bash
chmod +x download_qwen3.sh
./download_qwen3.sh
```

- Downloads `Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf` to the current directory
- Uses the `hf` CLI (`huggingface-cli download`) under the hood
- Skips download if the model file already exists
- After running, the model is ready for any script

---

### `run_llama_server.sh` — llama.cpp server only

Starts the llama.cpp server serving the model via an OpenAI-compatible API on port 8080.

```bash
chmod +x run_llama_server.sh
./run_llama_server.sh
```

**What it does:**
1. Checks if the model file exists; downloads it if missing
2. Launches `llama-server` serving the model on port 8080 with reasoning/thinking enabled
3. Exposes the OpenAI-compatible API at `http://localhost:8080/v1`

**Useful flags:**
- `--reasoning on` — enables Chain-of-Thought / thinking mode
- `--reasoning-format deepseek` — returns thoughts in `message.reasoning_content` for clean separation
- `--reasoning-budget -1` — unlimited thinking tokens (use a positive number to limit)

**Architecture:**
```
llama-server (localhost:8080) → Qwen3.6 Model
```

---

### `run_openwebui.sh` — Open WebUI only

Starts the Open WebUI Docker container. Requires `llama-server` to be running on port 8080 first.

```bash
chmod +x run_openwebui.sh
./run_openwebui.sh
# Then open http://localhost:3000 in your browser
```

**What it does:**
1. Starts the Open WebUI Docker container in detached mode
2. Configures it to connect to llama-server on `http://host.docker.internal:8080`
3. Opens the WebUI at `http://localhost:3000`

**Note:** Start this after `run_llama_server.sh` so the API endpoint is available.

---

### `cli_qwen3.sh` — Terminal-only mode

Runs the model directly in your terminal using `llama-cli`. No browser, no Docker — just raw text-in, text-out.

```bash
chmod +x cli_qwen3.sh
./cli_qwen3.sh
```

**What it does:**
1. Checks if the model file exists; downloads it if missing
2. Launches `llama-cli` with an interactive chat prompt and thinking enabled

**When to use:** Headless servers, SSH sessions, or when you prefer a terminal interface.

---

## ⚙️ llama.cpp Flags Explained

All three scripts pass these flags to the model. Here's what each one means:

| Flag | Value | Meaning |
|---|---|---|
| `--cache-type-k turbo4` | `turbo4` | Uses 4-bit TurboQuant for the K (key) KV cache. Drastically reduces KV cache VRAM usage while maintaining quality |
| `--cache-type-v turbo3` | `turbo3` | Uses 3-bit TurboQuant for the V (value) KV cache. Complements the K cache quantization for even more memory savings |
| `--n-gpu-layers 999` | `999` | Push as many model layers as possible into GPU VRAM. `999` means "all of them" — llama.cpp will use whatever fits |
| `--n-cpu-moe 41` | `41` | Keeps the MoE expert weights of the first 41 layers in CPU memory. This is critical for MoE models — it offloads the large expert routing weights from VRAM to RAM, freeing up GPU memory for the KV cache |
| `--reasoning on` | `on` | Enables Chain-of-Thought / thinking mode. The model will produce a reasoning trace before answering |
| `--reasoning-format deepseek` | `deepseek` | Returns reasoning thoughts in `message.reasoning_content` for clean separation from the final answer |
| `--reasoning-budget -1` | `-1` | Unlimited thinking tokens — let the model think as long as it needs |
| `--parallel 1` | `1` | Single request slot. You send one prompt and get one response. Prevents context collision in the WebUI |

### Key optimization takeaways:

- **TurboQuant (turbo4/turbo3)** is the game-changer here. Traditional llama.cpp KV cache quantization uses static 8-bit or 16-bit. TurboQuant dynamically compresses the KV cache during inference, often cutting VRAM usage by 3–5× compared to default caching. This is especially impactful for long context windows.
- **MoE CPU offloading** (`--n-cpu-moe`) is what makes running a 35B-parameter model feasible on a single consumer GPU. The active parameters route through the GPU, but the expert weights sit in system RAM.

---

## 🌐 Open WebUI (Docker Dashboard)

Open WebUI is used to provide a chat interface that looks like ChatGPT.

### It's Persistent

The Open WebUI container is configured with a named Docker volume (`open-webui-data`) that persists across container restarts. This means:

- **Chat history is saved** — your conversations survive container restarts, updates, and even system reboots
- **Settings are preserved** — custom configurations, user preferences, and API key setups persist
- **Files uploaded to the chat** (documents, images) are stored on disk

The volume is managed by Docker automatically:

```yaml
volumes:
  open-webui-data:     # Named volume, persists data
```

The container is also set to `restart: unless-stopped`, meaning Docker will automatically restart it if it crashes or if the system reboots.

### Container Details

| Setting | Value |
|---|---|
| Image | `ghcr.io/open-webui/open-webui:main` |
| Container name | `open-webui` |
| Host port | `3000` |
| Container port | `8080` |
| API base | `http://host.docker.internal:8080/v1` |

---

## 🔧 Configuration Files

### `opencode.json` — OpenCode AI configuration

Configures [OpenCode](https://opencode.ai) (an AI code editor) to use your local llama.cpp server as the model provider.

```json
{
  "provider": {
    "llama-local": {
      "name": "Llama.cpp (Local)",
      "baseURL": "http://localhost:8080/v1"
    }
  },
  "model": "llama-local/qwen3.6-35b-a3b"
}
```

⚠️ **Known issue:** OpenCode (OpenCode AI) is very resource-heavy — it's an Electron-based IDE that loads Chromium, multiple extensions, and heavy dependencies alongside the model inference. This makes it feel sluggish and unresponsive when paired with local inference.

**We strongly recommend using the [pi coding agent](https://github.com/earendil-works/pi-coding-agent) instead.** pi is:
- **Lightweight** — built on Node.js, no Electron overhead
- **Faster** — snappy response times even with local model inference
- **Better integrated** — purpose-built for terminal/SSH workflows
- **More efficient** — lower baseline resource usage means more resources for your model

Use the OpenCode config if you really want it, but **pi will give you a much better experience with this setup**.

### `pi.json` — pi coding agent provider config

Configures the pi coding agent to connect to your local llama.cpp server. This is the preferred configuration for coding tasks with this local model.

```json
{
  "providers": {
    "llama-cpp": {
      "baseUrl": "http://localhost:8080/v1",
      "api": "openai-completions",
      "apiKey": "none",
      "models": [{ "id": "Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf" }]
    }
  }
}
```

With `llama-server` running on port 8080, pi can be used as your local coding assistant — far more responsive and practical than OpenCode for this use case.

---

## 🚀 Quick Start

### Option 1: Web UI (recommended for beginners)

```bash
./run_llama_server.sh   # Start the API server in one terminal
./run_openwebui.sh      # Start Open WebUI in another terminal
# Then open http://localhost:3000 in your browser
```

### Option 2: Terminal only

```bash
./cli_qwen3.sh
```

### Option 3: Download separately, run later

```bash
./download_qwen3.sh
# Later:
./run_llama_server.sh   # or
./cli_qwen3.sh          # or
./run_openwebui.sh      # (it'll skip the download since the model already exists)
```

---

## 📁 Project Structure

```
.
├── download_qwen3.sh   # Download model only
├── cli_qwen3.sh        # Terminal-only inference
├── run_llama_server.sh # llama.cpp server (API on port 8080)
├── run_openwebui.sh    # Open WebUI Docker container
├── docker-compose.yml  # Open WebUI Docker config
├── opencode.json       # OpenCode AI config (see warnings above)
├── pi.json             # pi coding agent config (recommended)
├── .gitignore
└── README.md
```

Model file (`*.gguf`) is excluded from git as it's ~5GB and pulled from Hugging Face on first run.

---

## 🔧 Dependencies

| Tool | Purpose |
|---|---|
| `llama-server` / `llama-cli` | llama.cpp inference server and CLI (built with TurboQuant support) |
| `hf` (huggingface-cli) | Downloads models from Hugging Face |
| Docker / Docker Compose | Runs Open WebUI dashboard |
| `xdg-open` / `open` | Auto-opens browser on Linux / macOS |

---

## 🛠️ Troubleshooting

- **Model not downloading?** Make sure `hf` is logged in (`hf auth login`) if the repo requires authentication
- **Out of GPU memory?** Try lowering `--n-gpu-layers` (e.g., `32`) to force some layers to CPU
- **Slow inference?** Make sure your GPU is detected. Check `llama-server` logs for GPU info
- **WebUI won't connect?** Make sure `llama-server` is running first — it needs to be listening on port 8080 before Open WebUI can connect. Start `run_llama_server.sh` in one terminal, then `run_openwebui.sh` in another.
- **No thinking / reasoning output?** Verify `--reasoning on` is set in your server script. Open WebUI and pi will receive the reasoning content in the `message.reasoning_content` field.
- **pi not connecting?** Verify `llama-server` is running and `pi.json` points to the correct URL

---

## 📝 Notes

- The model downloads ~5GB on first run. Subsequent runs are instant.
- Open WebUI is on the `main` branch — it's the development build and may have occasional bugs.
- All scripts with model checks auto-create the model directory if needed.
