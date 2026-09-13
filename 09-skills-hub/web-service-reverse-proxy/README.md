# 網路服務反向代理、Port Forwarding 與背景啟動指南 (Web Service & Reverse Proxy Skill)

本 Skill 專門為 **HPC 高效能運算叢集（如國網中心 NCHC Taiwania / Open OnDemand）** 以及各類遠端伺服器環境設計，提供在「子路徑反向代理（Subpath Reverse Proxy）」下安全、穩定啟動各類網頁服務（Node.js / Python）與 AI Agent 的最佳實踐。

---

## 目錄

1. [為什麼需要這個 Skill？（常見踩坑問題）](#1-為什麼需要這個-skill常見踩坑問題)
2. [動態分配連接埠 (Port) 與三種 Port Forwarding 途徑](#2-動態分配連接埠-port-與三種-port-forwarding-途徑)
3. [背景管理避坑：為什麼要用 tmux？](#3-背景管理避坑為什麼要用-tmux)
4. [Node.js / 前端框架設定指南 (Vite, React, Express)](#4-nodejs--前端框架設定指南)
5. [Python 網頁框架設定指南 (Streamlit, Gradio, FastAPI, Flask)](#5-python-網頁框架設定指南)
6. [萬用背景啟動腳本模板 (`start-service.sh`)](#6-萬用背景啟動腳本模板-start-servicesh)
7. [國網中心網址拼裝與驗證規則](#7-國網中心網址拼裝與驗證規則)
8. [如何讓 AI 助理調用此 Skill？](#8-如何讓-ai-助理調用此-skill)

---

## 1. 為什麼需要這個 Skill？（常見踩坑問題）

在遠端伺服器（如國網中心 Open OnDemand）開啟網頁服務時，外網存取網址通常帶有特定的子路徑前綴：
```text
https://f1-stn01.nchc.org.tw/rnode/<節點名稱>/<連接埠>/
```

若未正確設定 Base URL，90% 以上的使用者會遇到以下兩大問題：

### 地雷一：靜態資源 404 Not Found
* **原因**：大部分前端框架預設編譯為「根目錄絕對路徑」（例如 `<script src="/assets/index.js">`）。
* **結果**：瀏覽器會直接向 `https://f1-stn01.nchc.org.tw/assets/index.js` 抓取，漏掉了 `/rnode/...` 子路徑，導致所有 JS/CSS 全部 404 破圖。
* **解法**：設定 `base: './'`（相對路徑）或指定明確的 `basePath` / `root_path`。

### 地雷二：Blocked request. This host is not allowed
* **原因**：現代框架（如 Vite 6+、Django 等）內建主機安全過濾，當發現 HTTP `Host` 標頭是外網代理主機（如 `f1-stn01.nchc.org.tw`）而非 `localhost` 時，會直接攔截。
* **解法**：設定 `allowedHosts: true`。

---

## 2. 動態分配連接埠 (Port) 與三種 Port Forwarding 途徑

在多人共用的伺服器上，寫死固定埠號（如 3000、5173、8080）極易發生 `EADDRINUSE` 衝突。

### A. 動態取得閒置 Port（一行指令）
透過 Python 隨機綁定 0 號埠，由作業系統安全配發可用 Port：
```bash
myport=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
myhostname=$(hostname -s)
```

### B. 三種對外存取與轉發途徑

```text
途徑 1：國網中心原生 OOD 代理（最直接、最穩定）
https://f1-stn01.nchc.org.tw/rnode/<myhostname>/<myport>/
      └── 流量直接穿透到服務監聽的 0.0.0.0:<myport>，不依賴 Code-Server。

途徑 2：Code-Server 內建 Port Forwarding 代理
https://f1-stn01.nchc.org.tw/rnode/<myhostname>/<cs_port>/proxy/<myport>/
      └── 透過 Code-Server 內建的 HTTP 反向代理轉發。
      └── 在 VS Code 下方「連接埠 (Ports)」面板輸入 <myport> 即自動產生。

途徑 3：本機 SSH 隧道 (SSH Port Forwarding)
ssh -L <myport>:localhost:<myport> user@ilgn01.nchc.org.tw
      └── 在本機電腦瀏覽器直接輸入 http://localhost:<myport>。
```

### C. 在專案中設定 VS Code 自動 Port Forwarding
在專案的 `.vscode/settings.json` 加入，VS Code 一開就會自動標記與轉發：
```json
{
  "remote.portsAttributes": {
    "5173": {
      "label": "Web 服務 (React / Python)",
      "onAutoForward": "notify",
      "elevateIfNeeded": false
    }
  }
}
```

---

## 3. 背景管理避坑：為什麼要用 tmux？

### 嚴禁在 SSH 終端機隨意使用 `nohup <cmd> &` 啟動含有互動子行程的服務！
* **原因**：當程式被放到背景（`&`），但仍連接著終端機時，如果底層有任何工具執行了 `bash -i`（互動模式），Linux 核心會向該背景行程發送 `SIGTTIN` 信號。
* **後果**：行程陷入無窮訊號重試迴圈，單核 CPU 飆到 90%+，整個主執行緒死鎖（例如 ChatGPT / Codex extension 會一直轉圈圈無法登入）。

### 最佳解：使用 `tmux` 啟動背景服務
每個 tmux session 都是獨立且合法的虛擬終端（PTY），絕不觸發 `SIGTTIN`，隨時可進出：
```bash
# 1. 在背景建立並啟動服務
tmux new-session -d -s my-service "npm run preview"

# 2. 查看當前所有背景服務
tmux ls

# 3. 走進去查看即時輸出
tmux attach -t my-service
# (退回命令列：先按 Ctrl+b，放開後按 d)

# 4. 關閉服務
tmux kill-session -t my-service
```

---

## 4. Node.js / 前端框架設定指南

### A. Vite (React / Vue)
1. 在 `vite.config.js` 加入 `base: './'` 與 `allowedHosts: true`：
   ```javascript
   import { defineConfig } from 'vite';
   import react from '@vitejs/plugin-react';

   export default defineConfig({
     plugins: [react()],
     base: './', // 關鍵：編譯為相對路徑
     server: {
       host: '0.0.0.0',
       port: 5173,
       allowedHosts: true, // 關鍵：放行反向代理主機標頭
     },
     preview: {
       host: '0.0.0.0',
       port: 5173,
       allowedHosts: true,
     }
   });
   ```
2. **務必使用 Production Preview 模式提供服務**：
   ```bash
   npm run build && npm run preview -- --host 0.0.0.0 --port 5173
   ```
   *註：Vite 開發模式（dev）內建的熱更新引擎 `/@vite/client` 會強制走根目錄，在子路徑反向代理下容易 404；生產打包後的 preview 模式 100% 穩定相容。*

### B. Express.js
```javascript
const express = require('express');
const app = express();
app.set('trust proxy', true); // 信任反向代理標頭
app.use(express.static('dist')); // 提供打包靜態檔案
app.listen(3000, '0.0.0.0');
```

---

## 5. Python 網頁框架設定指南

### A. Streamlit
Streamlit 需透過 `--server.baseUrlPath` 修正 WebSocket 與靜態路徑：
```bash
HOSTNAME=$(hostname -s)
PORT=8501

tmux new-session -d -s streamlit-app "streamlit run app.py \
  --server.address 0.0.0.0 \
  --server.port $PORT \
  --server.baseUrlPath /rnode/${HOSTNAME}/${PORT} \
  --server.enableCORS false \
  --server.enableXsrfProtection false"
```

### B. Gradio
在 Python 程式中設定 `root_path`：
```python
import gradio as gr
import socket

hostname = socket.gethostname().split('.')[0]
port = 7860

demo = gr.Interface(fn=lambda x: f"Hello, {x}!", inputs="text", outputs="text")

demo.launch(
    server_name="0.0.0.0",
    server_port=port,
    root_path=f"/rnode/{hostname}/{port}" # 關鍵
)
```

### C. FastAPI + Uvicorn
在程式與指令中同時傳入 `root_path`，確保 Swagger UI (`/docs`) 能正常開啟：
```python
from fastapi import FastAPI
import socket

hostname = socket.gethostname().split('.')[0]
port = 8000

app = FastAPI(root_path=f"/rnode/{hostname}/{port}")

@app.get("/")
def read_root():
    return {"status": "ok"}
```
啟動指令：
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --root-path "/rnode/$(hostname -s)/8000" --proxy-headers
```

### D. Python 內建靜態檔案伺服器
```bash
python3 -m http.server 8000 --bind 0.0.0.0
```
*(Python 內建伺服器預設採用相對路徑，開箱即可搭配 OOD 子路徑使用)*

---

## 6. 萬用背景啟動腳本模板 (`start-service.sh`)

任何專案皆可複製使用的標準一鍵啟動腳本：

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
  echo "已在 tmux 背景啟動 '$SESSION'"
fi

# 4. 輸出存取網址並保存
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

## 7. 國網中心網址拼裝與驗證規則

1. **網址結尾「斜線 `/`」絕對不能少**：
   * ✅ 正確：`https://f1-stn01.nchc.org.tw/rnode/ilgn01/5173/`
   * ❌ 錯誤：`https://f1-stn01.nchc.org.tw/rnode/ilgn01/5173`（漏掉斜線會導致瀏覽器相對路徑解析錯誤跳層）。
2. **發布前終端機驗證指令**：
   ```bash
   # 模擬代理主機發送請求，檢查是否回傳 HTTP 200 OK
   curl -I -H "Host: f1-stn01.nchc.org.tw" http://localhost:5173/
   ```

---

## 8. 如何讓 AI 助理調用此 Skill？

在往後的任何對話中，只要您需要：
* 開啟新的 Node.js / React / Vue 專案
* 開啟 Python Streamlit / Gradio / FastAPI 應用
* 遇到網頁反向代理 404 或主機被阻擋的問題

您可以直接向 AI 助理說：
> **「請依照 `web-service-reverse-proxy` skill 的規範，幫我建立並在背景啟動服務。」**
