---
name: web-service-reverse-proxy
description: >-
  Comprehensive guide and runbook for configuring web applications and starting background services
  under subpath reverse proxies (e.g. Open OnDemand rnode proxy, code-server proxy, HPC clusters).
  Covers dynamic port allocation, Code-Server Port Forwarding configuration, Base URL / relative path
  settings, AllowedHosts validation, background execution with tmux/setsid to prevent SIGTTIN deadlocks,
  and universal startup templates for Node.js (Vite, React, Vue, Next.js, Express) and Python (Streamlit, Gradio, FastAPI, Flask).
---

# Web Service & Reverse Proxy Configuration Guide (Node.js & Python)

This skill provides step-by-step procedures and templates for launching web applications in HPC / remote server environments (such as NCHC Open OnDemand, Forerunner 1 / Taiwania clusters, or code-server) where services must be accessed through **subpath reverse proxies** (e.g. `/rnode/<hostname>/<port>/` or `/proxy/<port>/`).

---

## 1. The Core Problem: Subpath Reverse Proxies

When running a web service behind a subpath reverse proxy, the public URL is:
```text
https://<proxy-domain>/rnode/<hostname>/<port>/
```
Notice the subpath prefix `/rnode/<hostname>/<port>/`. Without proper configuration, two major failures occur:

1. **Broken Asset Links & 404s**:
   - Web frameworks default to root-relative paths like `<script src="/assets/app.js">`.
   - The browser requests `https://<proxy-domain>/assets/app.js` (omitting the subpath prefix), triggering a **404 Not Found**.
2. **Blocked Requests (Host Validation)**:
   - Modern frameworks (Vite 6+, Django, Rails, etc.) inspect the HTTP `Host` header.
   - Because the proxy passes `Host: <proxy-domain>`, the local server rejects it with `Blocked request. This host is not allowed`.

---

## 2. Dynamic Port Allocation & Port Forwarding Pathways

On shared multi-user servers (like HPC login nodes `ilgn01`), hardcoding fixed ports (e.g. 3000, 5173, 8080) causes frequent `EADDRINUSE` port collision errors.

### A. Dynamic Free Port Discovery (Universal One-Liner)
Use Python's OS socket binding to find a guaranteed unallocated port:
```bash
myport=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
myhostname=$(hostname -s)
```

### B. Three Access & Port Forwarding Pathways

```text
Pathway 1 (OOD Direct):
https://f1-stn01.nchc.org.tw/rnode/<myhostname>/<myport>/
      └── Directly reaches service via Open OnDemand rnode proxy.

Pathway 2 (Code-Server Proxy):
https://f1-stn01.nchc.org.tw/rnode/<myhostname>/<cs_port>/proxy/<myport>/
      └── Proxied through Code-Server's built-in HTTP proxy (VSCODE_PROXY_URI).

Pathway 3 (SSH Tunnel to Client):
ssh -L <myport>:localhost:<myport> user@ilgn01.nchc.org.tw
      └── Client opens http://localhost:<myport> locally.
```

### C. Configuring Code-Server Port Forwarding in `.vscode/settings.json`
To make VS Code automatically detect, label, and forward the port without typing:
```json
{
  "remote.portsAttributes": {
    "5173": {
      "label": "Web Application",
      "onAutoForward": "notify",
      "elevateIfNeeded": false
    }
  }
}
```
Or in Code-Server's UI:
1. Open the **"Ports" (連接埠)** tab next to Terminal.
2. Click **"Forward a Port" (轉送連接埠)**.
3. Enter `<myport>`.
4. Code-Server automatically maps it to `https://<domain>/rnode/<host>/<cs_port>/proxy/<myport>/`.

---

## 3. Background Service Management: Preventing TTY & SIGTTIN Deadlocks

### Golden Rule: Always Use `tmux` for Web Services & Agents
Do **not** use raw `nohup cmd &` from an interactive SSH terminal if child processes might execute interactive subshells (`bash -i`). This triggers an infinite `SIGTTIN` signal loop, freezing the process at 90%+ CPU.

#### Recommended: `tmux` (Detached Session)
```bash
SESSION_NAME="my-web-app"

# Start service in background
tmux new-session -d -s "$SESSION_NAME" "cd /path/to/project && <start-command>"

# Check status
tmux ls

# Attach to view logs / interactive console
tmux attach -t "$SESSION_NAME"
# (To detach: press Ctrl + b, then release and press d)

# Stop service
tmux kill-session -t "$SESSION_NAME"
```

#### Alternative: Clean Daemon with `setsid`
```bash
setsid <start-command> < /dev/null > service.log 2>&1 &
echo $! > service.pid
```

---

## 4. Node.js & Frontend Frameworks Setup

### A. Vite (React / Vue / Svelte)

#### 1. Configuration (`vite.config.js`)
```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // CRITICAL 1: Use relative base path for all compiled assets
  base: './',
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: false,
    // CRITICAL 2: Allow reverse proxy host header (e.g. f1-stn01.nchc.org.tw)
    allowedHosts: true,
  },
  preview: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: false,
    allowedHosts: true,
  }
});
```

#### 2. Best Practice: Production Preview Mode
In Vite development mode (`npm run dev`), Vite's HMR client injects hardcoded `/@vite/client` paths which bypass subpath proxies. **Always build and serve via `preview` for reverse proxy access**:
```bash
# Build with relative paths and start preview
npm run build && npm run preview -- --host 0.0.0.0 --port 5173
```

---

### B. Next.js

In `next.config.js`:
```javascript
const hostname = process.env.HOSTNAME || 'localhost';
const port = process.env.PORT || 3000;

module.exports = {
  // Set basePath to match the proxy subpath
  basePath: `/rnode/${hostname}/${port}`,
  assetPrefix: `/rnode/${hostname}/${port}`,
};
```

---

### C. Express / Node.js HTTP Server

Use relative paths for static files and enable trust proxy:
```javascript
import express from 'express';
import path from 'path';

const app = express();
const port = process.env.PORT || 3000;

// Trust reverse proxy headers
app.set('trust proxy', true);

// Serve static assets
app.use(express.static(path.join(process.cwd(), 'dist')));

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on 0.0.0.0:${port}`);
});
```

---

## 5. Python Web Frameworks Setup

### A. Streamlit

Streamlit has built-in parameters for proxy subpaths and CORS:
```bash
HOSTNAME=$(hostname -s)
PORT=8501

streamlit run app.py \
  --server.address "0.0.0.0" \
  --server.port "$PORT" \
  --server.baseUrlPath "/rnode/${HOSTNAME}/${PORT}" \
  --server.enableCORS false \
  --server.enableXsrfProtection false
```
*Note: `--server.baseUrlPath` ensures all Streamlit WebSockets and static scripts connect to the subpath.*

---

### B. Gradio

In Python script:
```python
import gradio as gr
import socket

hostname = socket.gethostname().split('.')[0]
port = 7860

def greet(name):
    return f"Hello, {name}!"

demo = gr.Interface(fn=greet, inputs="text", outputs="text")

# root_path tells Gradio to route internal API & WebSocket calls through the proxy subpath
demo.launch(
    server_name="0.0.0.0",
    server_port=port,
    root_path=f"/rnode/{hostname}/{port}",
    share=False
)
```

---

### C. FastAPI & Uvicorn

In `main.py`:
```python
import socket
from fastapi import FastAPI

hostname = socket.gethostname().split('.')[0]
port = 8000

# Set root_path so Swagger docs (/docs) and OpenAPI schema resolve correctly
app = FastAPI(root_path=f"/rnode/{hostname}/{port}")

@app.get("/")
def read_root():
    return {"status": "ok", "message": "FastAPI behind OOD reverse proxy"}
```

Run command:
```bash
HOSTNAME=$(hostname -s)
PORT=8000

uvicorn main:app \
  --host 0.0.0.0 \
  --port "$PORT" \
  --root-path "/rnode/${HOSTNAME}/${PORT}" \
  --proxy-headers
```

---

### D. Flask

Use Werkzeug's `ProxyFix` middleware to handle `X-Forwarded-*` headers:
```python
from flask import Flask, url_for
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
# Handles X-Forwarded-For, X-Forwarded-Proto, X-Forwarded-Host, X-Forwarded-Prefix
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

@app.route("/")
def index():
    return "Hello from Flask behind reverse proxy!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

---

### E. Python Simple HTTP Server (Static Files)

Python's built-in HTTP server generates relative directory listings by default:
```bash
python3 -m http.server 8000 --bind 0.0.0.0
```
When accessed via `https://<proxy-domain>/rnode/<hostname>/8000/`, all links resolve correctly relative to the current URL.

---

## 6. Universal Background Launch Script Template (`start-service.sh`)

Here is a turnkey, reusable bash template to start ANY web service in tmux with dynamic port allocation and URL reporting:

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="my-app"
SESSION="svc-${APP_NAME}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. 隨機取得保證未被佔用的 Port
PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
HOSTNAME=$(hostname -s)

# 2. 定義啟動指令 (以 Vite 為例，若是 Python 請抽換)
# Node.js: CMD="cd '$DIR' && npm run build && npm run preview -- --host 0.0.0.0 --port $PORT"
# Python Streamlit: CMD="cd '$DIR' && streamlit run app.py --server.address 0.0.0.0 --server.port $PORT --server.baseUrlPath /rnode/$HOSTNAME/$PORT --server.enableCORS false"
# Python FastAPI: CMD="cd '$DIR' && uvicorn main:app --host 0.0.0.0 --port $PORT --root-path /rnode/$HOSTNAME/$PORT --proxy-headers"
CMD="cd '$DIR' && npm run build && npm run preview -- --host 0.0.0.0 --port $PORT"

# 3. 在 tmux 背景中啟動
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "服務 '$SESSION' 已經在運行中！"
else
  tmux new-session -d -s "$SESSION" "$CMD"
  echo "已在 tmux 背景啟動 '$SESSION' (PID: $!)"
fi

# 4. 輸出存取網址與日誌
OOD_URL="https://f1-stn01.nchc.org.tw/rnode/${HOSTNAME}/${PORT}/"
echo "=============================================="
echo "服務名稱: ${APP_NAME}"
echo "節點名稱: ${HOSTNAME}"
echo "分配連接埠: ${PORT}"
echo "OOD 存取網址: ${OOD_URL}"
echo "tmux 監控指令: tmux attach -t ${SESSION}"
echo "=============================================="
echo "${OOD_URL}" > "$DIR/service-url.txt"
```

---

## 7. URL Construction & Verification Checklist

1. **Trailing Slash is Mandatory**:
   Always include the trailing slash in the proxy URL:
   * Correct: `https://f1-stn01.nchc.org.tw/rnode/<hostname>/<port>/`
   * Incorrect: `https://f1-stn01.nchc.org.tw/rnode/<hostname>/<port>` (causes relative paths `./` to resolve one level too high!).
2. **Local Verification Command**:
   Before giving the URL to users, verify both HTML and static assets return HTTP 200 with proxy host headers:
   ```bash
   # Test main page with proxy host header
   curl -I -H "Host: f1-stn01.nchc.org.tw" http://localhost:<port>/

   # Test static asset resolution
   curl -I http://localhost:<port>/assets/<bundle>.js
   ```
3. **Common Proxy URL Formats on NCHC**:
   - Open OnDemand `rnode`: `https://f1-stn01.nchc.org.tw/rnode/$(hostname -s)/<port>/`
   - Code-Server Proxy: `https://f1-stn01.nchc.org.tw/rnode/$(hostname -s)/<cs_port>/proxy/<port>/`
