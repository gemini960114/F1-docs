# HPC 實戰指南：網頁服務反向代理、Port Forwarding 與背景啟動

本教學手冊專門為 **HPC 高效能運算叢集（如國網中心 NCHC Taiwania / Open OnDemand）** 以及各類遠端 Linux 伺服器環境設計，深入探討如何在「子路徑反向代理（Subpath Reverse Proxy）」下安全、穩定啟動各類網頁應用（Node.js / Python）與 AI Agent Web UI。

> [!TIP]
> **🎯 本章在全系列中的定位：通往 Code-Server 瀏覽器工作台的跨網橋樑**  
> 了解動態 Port 分配與子路徑反向代理（`/rnode/<host>/<port>/`），是**啟動第 03 章 Code-Server (VS Code Web) 的底層技術核心**。  
> 一旦掌握這套機制，您就能把超級電腦上的各種服務（VS Code、Jupyter、Streamlit、MultiQC 互動報告）透過瀏覽器流暢存取，徹底告別傳統文字終端機！

---

## 📌 目錄 (Table of Contents)
- [1. 核心問題：為什麼在 HPC 開網頁這麼容易踩坑？](#1-核心問題為什麼在-hpc-開網頁這麼容易踩坑)
- [2. 動態連接埠分配與三種 Port Forwarding 途徑](#2-動態連接埠分配與三種-port-forwarding-途徑)
- [3. 背景行程管理：為什麼絕對不能隨意用 nohup ＆？](#3-背景行程管理為什麼絕對不能隨意用-nohup-)
- [4. 前端框架設定指南 (Node.js / Vite / React / Next.js)](#4-前端框架設定指南-nodejs--vite--react--nextjs)
- [5. Python 網頁框架設定指南 (Streamlit / Gradio / FastAPI / Flask)](#5-python-網頁框架設定指南-streamlit--gradio--fastapi--flask)
- [6. 萬用背景啟動腳本 (`universal_start.sh`)](#6-萬用背景啟動腳本-universal_startsh)
- [7. 網址拼裝規則與驗證清單](#7-網址拼裝規則與驗證清單)

---

## 1. 核心問題：為什麼在 HPC 開網頁這麼容易踩坑？

> [!NOTE]
> **💡 非資工/初學者平滑閱讀指引**：
> 如果您是生醫、物理、化學或機械背景的研究員，**請別被本章提到的 Vite、React 或 Next.js 嚇到！您不需要成為前端工程師**。
> 本章對純科研人員的核心價值只有兩點：
> 1. **搞懂 OOD 網址結構**：明白為什麼超級電腦上的網址長成 `https://f1-stn01.nchc.org.tw/rnode/<節點>/<Port>/`。
> 2. **掌握通用背景啟動**：學會用 `tmux` 與動態 Port 啟動服務（如 Code-Server、Jupyter、Streamlit 或 MultiQC 報表）。
> *章節中關於前端框架 (Node.js/Vite) 的深層設定屬於「進階選修」，非前端開發者可直接跳至第 2 節與第 5、6 節的萬用啟動腳本！*

在個人本機開發時，網頁伺服器通常綁定 `http://localhost:5173/`。但在超級電腦或遠端伺服器上，瀏覽器是透過平台反向代理（Reverse Proxy）存取您的服務，網址帶有特定的子路徑前綴：

```text
https://f1-stn01.nchc.org.tw/rnode/<節點主機名稱>/<連接埠號>/
```

> [!NOTE]
> `f1-stn01.nchc.org.tw` (`140.110.122.213`) 與 `f1-stn02.nchc.org.tw` (`140.110.122.214`) 即為創進一號官方所定義的**「特殊工作流程節點 (Special Workflow Nodes)」**，專門提供 Open OnDemand (OOD) Web 門戶與子路徑反向代理服務！

若未對框架進行調整，有 90% 以上的使用者會遇到以下兩大毀滅性地雷：

### 地雷一：靜態資源全部 404 Not Found (破圖/白畫面)
* **原因**：現代前端框架預設編譯為「根目錄絕對路徑」（例如 `<script src="/assets/index.js">`）。
* **結果**：瀏覽器向伺服器請求時，會向 `https://f1-stn01.nchc.org.tw/assets/index.js` 請求，**遺漏了中間的 `/rnode/<host>/<port>/` 子路徑**，導致所有 JavaScript 與 CSS 全部 404，網頁一片空白。
* **解法**：設定 `base: './'`（相對路徑）或指定框架的 `basePath` / `root_path`。

### 地雷二：Blocked request. This host is not allowed
* **原因**：現代框架（例如 Vite 6+、Django、Rails 等）內建主機安全性校驗（Host Header Validation）。當反向代理將外部流量轉送進來時，HTTP 標頭帶有 `Host: f1-stn01.nchc.org.tw`，本機伺服器會認為遭遇 DNS 重綁定攻擊而直接拒絕連線。
* **解法**：在框架設定中明確放行反向代理主機，例如 Vite 的 `allowedHosts: true`。

---

## 2. 動態連接埠分配與三種 Port Forwarding 途徑

在多人共用的伺服器上（例如登入節點 `ilgn01`），**嚴禁寫死固定埠號**（如 3000、5173、8080），否則會頻繁出現 `EADDRINUSE: address already in use` 錯誤。

### A. 動態取得未被佔用的連接埠 (Universal One-Liner)
透過 Python 隨機綁定 0 號埠，由 Linux 核心配發保證可用的 Port：
```bash
myport=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
myhostname=$(hostname -s)
```

### B. 三種外部存取途徑比較

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
      └── 在個人本機電腦瀏覽器直接輸入 http://localhost:<myport>。
```

### C. 在 VS Code / Code-Server 自動辨識連接埠
在專案目錄建立 [`.vscode/settings.json`](./templates/vscode_settings.json)，VS Code 便會在服務啟動時自動彈出轉發通知：
```json
{
  "remote.portsAttributes": {
    "5173": {
      "label": "Web 應用服務",
      "onAutoForward": "notify",
      "elevateIfNeeded": false
    }
  }
}
```

---

## 3. 背景行程管理：為什麼絕對不能隨意用 nohup ＆？

### ☠️ 地雷警告：`SIGTTIN` 信號死鎖與單核 100% CPU 飆高
在遠端 SSH 環境中，千萬不要隨意下達 `nohup command &` 啟動複雜應用！
* **原因**：若程式被放到背景執行（`&`），但仍繼承了終端機的 session，一旦底層工具（如 Python 子行程、npm、AI 代理工具）嘗試調用 `bash -i` 互動模式，Linux 核心會向該背景行程發送 `SIGTTIN`（要求終端輸入）。
* **後果**：行程卡死在無窮信號重試迴圈中，**單核 CPU 飆升至 90%~100%**，但主程序完全停止回應（例如 Code-Server 擴充套件持續轉圈無法登入）。

### 🛡️ 最佳解：永遠使用 `tmux` 啟動網頁服務
`tmux` 會為每個 session 分配獨立且合法的偽終端（PTY），完全免疫 `SIGTTIN`，且即使斷線服務依然持續運行：

```bash
SESSION_NAME="my-web-app"

# 1. 在背景建立並啟動服務
tmux new-session -d -s "$SESSION_NAME" "npm run preview -- --host 0.0.0.0 --port 5173"

# 2. 查看所有背景服務
tmux ls

# 3. 進入終端查看即時日誌
tmux attach -t "$SESSION_NAME"
# (脫離終端回到命令列: 先按 Ctrl+B，放開後按 D)

# 4. 關閉服務
tmux kill-session -t "$SESSION_NAME"
```

---

## 4. 前端框架設定指南 (Node.js / Vite / React / Next.js)

### A. Vite (React / Vue / Svelte)
在 [`vite.config.js`](./templates/vite.config.js) 中加入兩大關鍵設定：

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // 核心設定 1：使用相對路徑打包所有 CSS/JS 靜態資源 (解決 404 破圖)
  base: './',
  server: {
    host: '0.0.0.0',
    port: 5173,
    // 核心設定 2：放行反向代理標頭 (解決 Blocked request. This host is not allowed)
    allowedHosts: true,
  },
  preview: {
    host: '0.0.0.0',
    port: 5173,
    allowedHosts: true,
  }
});
```

> [!IMPORTANT]
> **最佳實踐：使用 Production Preview 模式！**  
> Vite 開發模式（`npm run dev`）內建的熱更新客戶端（`/@vite/client`）會強制走根目錄，在子路徑反向代理下容易故障。**強烈建議先打包再啟動預覽**：
> ```bash
> npm run build && npm run preview -- --host 0.0.0.0 --port 5173
> ```

### B. Next.js
在 `next.config.js` 中動態設定子路徑：
```javascript
const hostname = process.env.HOSTNAME || 'ilgn01';
const port = process.env.PORT || 3000;

module.exports = {
  basePath: `/rnode/${hostname}/${port}`,
  assetPrefix: `/rnode/${hostname}/${port}`,
};
```

### C. Express.js
```javascript
const express = require('express');
const app = express();

app.set('trust proxy', true); // 信任反向代理標頭 (X-Forwarded-*)
app.use(express.static('dist')); // 提供打包靜態檔案

app.listen(3000, '0.0.0.0');
```

---

## 5. Python 網頁框架設定指南 (Streamlit / Gradio / FastAPI / Flask)

### A. Streamlit
Streamlit 需透過 `--server.baseUrlPath` 修正 WebSocket 與靜態腳本路徑：
```bash
HOSTNAME=$(hostname -s)
PORT=8501

tmux new-session -d -s svc-streamlit "streamlit run app.py \
  --server.address 0.0.0.0 \
  --server.port ${PORT} \
  --server.baseUrlPath /rnode/${HOSTNAME}/${PORT} \
  --server.enableCORS false \
  --server.enableXsrfProtection false"
```
*(參考範本：[`templates/streamlit_app.py`](./templates/streamlit_app.py) 與 [`templates/start_streamlit.sh`](./templates/start_streamlit.sh))*

---

### B. Gradio
在 Python 程式碼中設定 `root_path`：
```python
import gradio as gr
import socket

hostname = socket.gethostname().split('.')[0]
port = 7860

demo = gr.Interface(fn=lambda x: f"Hello, {x}!", inputs="text", outputs="text")

# 核心關鍵: 指定 root_path 為 /rnode/<hostname>/<port>
demo.launch(
    server_name="0.0.0.0",
    server_port=port,
    root_path=f"/rnode/{hostname}/{port}",
    share=False
)
```
*(參考範本：[`templates/gradio_app.py`](./templates/gradio_app.py))*

---

### C. FastAPI + Uvicorn
在程式與指令中同步傳入 `root_path`，以確保 Swagger UI (`/docs`) 能正常載入：

在 `main.py` 中：
```python
import socket
from fastapi import FastAPI

hostname = socket.gethostname().split('.')[0]
port = 8000

app = FastAPI(root_path=f"/rnode/{hostname}/{port}")

@app.get("/")
def read_root():
    return {"status": "ok", "docs": f"/rnode/{hostname}/{port}/docs"}
```

啟動指令：
```bash
uvicorn main:app \
  --host 0.0.0.0 \
  --port 8000 \
  --root-path "/rnode/$(hostname -s)/8000" \
  --proxy-headers
```
*(參考範本：[`templates/fastapi_app.py`](./templates/fastapi_app.py) 與 [`templates/start_fastapi.sh`](./templates/start_fastapi.sh))*

---

### D. Python 內建靜態伺服器 (Simple HTTP Server)
Python 內建的 `http.server` 預設採相對路徑，開箱即可搭配 OOD 子路徑使用：
```bash
python3 -m http.server 8000 --bind 0.0.0.0
```

---

## 6. 萬用背景啟動腳本 (`universal_start.sh`)

本教學提供了一份開箱即用的萬用腳本 [`scripts/universal_start.sh`](./scripts/universal_start.sh)，能自動配發閒置 Port、啟動 tmux、並印出完整的 OOD 存取網址：

### 使用方式
```bash
cd ~/hpc-tutorial/02-web-service-reverse-proxy/scripts

# 範例：啟動一個簡易 HTML 伺服器
bash universal_start.sh my-html "python3 -m http.server {PORT} --bind 0.0.0.0"

# 範例：啟動 Streamlit
bash universal_start.sh my-st "streamlit run app.py --server.address 0.0.0.0 --server.port {PORT} --server.baseUrlPath /rnode/{HOSTNAME}/{PORT} --server.enableCORS false"
```

### 輸出範例
```text
========================================================
🎉 網頁服務已成功於背景啟動！
========================================================
服務名稱      : my-html
tmux 會話名稱 : svc-my-html
主機節點      : ilgn01
分配連接埠    : 43219
執行指令      : python3 -m http.server 43219 --bind 0.0.0.0
--------------------------------------------------------
🌐 國網中心 OOD 外部存取網址 (結尾斜線不可省略):
👉 https://f1-stn01.nchc.org.tw/rnode/ilgn01/43219/
========================================================
```

---

## 7. 網址拼裝規則與驗證清單

1. **網址末端斜線 `/` 絕對不能漏掉**：
   * ✅ **正確**：`https://f1-stn01.nchc.org.tw/rnode/ilgn01/5173/`
   * ❌ **錯誤**：`https://f1-stn01.nchc.org.tw/rnode/ilgn01/5173`  
     *(缺少最後的斜線時，瀏覽器會把 `5173` 當成檔案而非目錄，導致所有相對路徑 `./assets/` 向上跳一層解析成 `/rnode/assets/` 而引發 404)*
2. **服務發布前終端機驗證指令**：
   在發布網址給使用者前，可在登入節點上執行模擬請求：
   ```bash
   # 檢查首頁是否正確放行外部 Host 標頭 (需回傳 HTTP 200 OK)
   curl -I -H "Host: f1-stn01.nchc.org.tw" http://localhost:<port>/
   ```

---

👉 **下一步**：進入 **[第 03 章：超級電腦運行 Code-Server (VS Code Web)](../03-code-server-on-hpc/)**，運用本章學到的反向代理與動態埠技術，打造屬於自己的雲端 IDE！
