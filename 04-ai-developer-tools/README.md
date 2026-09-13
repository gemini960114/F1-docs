# HPC 實戰指南：AI 開發工具鏈、VS Code 擴充套件與 OpenCode 國網模型配置

本教學手冊專門為在超級電腦（HPC）上進行人工智慧與資料科學研究的開發者設計。本章節將說明如何為 Code-Server 配置核心開發與 AI 擴充套件，安裝 **Antigravity CLI (`agy`)** 與 **OpenCode CLI**，並深入診斷與提供國網中心（NCHC GenAI / Medusa）的大模型 API 設定方案。

---

## 📌 目錄 (Table of Contents)
- [1. VS Code / Code-Server 核心與 AI 擴充套件安裝](#1-vs-code--code-server-核心與-ai-擴充套件安裝)
- [2. AI 命令行工具安裝：Antigravity CLI (agy) 與 OpenCode](#2-ai-命令行工具安裝antigravity-cli-agy-與-opencode)
- [3. OpenCode 國網中心設定檔診斷與修復報告](#3-opencode-國網中心設定檔診斷與修復報告)
- [4. 正確標準版 opencode.json 配置方案](#4-正確標準版-opencodejson-配置方案)
- [5. 國網中心支援模型清單與場景推薦](#5-國網中心支援模型清單與場景推薦)
- [6. 實機測試與模型呼叫指令](#6-實機測試與模型呼叫指令)
- [7. AI Agent 專屬 HPC 治理規則：AGENTS.md 實務](#7-ai-agent-專屬-hpc-治理規則agentsmd-實務)
- [8. 延伸整合：國網官方 Ollama 本地大模型部署方案](#8-延伸整合國網官方-ollama-本地大模型部署方案)
- [9. 網路避坑提醒：no_proxy 排除國網內網端點 (進階選修)](#9-網路避坑提醒no_proxy-排除國網內網端點-進階選修)

---

## 1. VS Code / Code-Server 核心與 AI 擴充套件安裝

> [!NOTE]
> **🖥️ 瀏覽器操作提醒**：
> 請確認您已經透過瀏覽器進入第 03 章建立的 **Code-Server Web UI**。  
> 按下 **``Ctrl + ` ``** 展開整合式終端機，或點擊左側導覽列的 **Extensions 圖示 (`Ctrl + Shift + X`)**，本章所有套件安裝與 AI 設定都在這個瀏覽器視窗中直接完成！

在 Code-Server 中，您可以透過終端機指令一鍵安裝所有核心開發套件與當前主流的 AI 輔助插件。

### A. 推薦安裝之套件清單

| 套件類別 | 擴充套件識別碼 (Extension ID) | 功能說明 |
| :--- | :--- | :--- |
| **Jupyter 互動運算** | `ms-toolsai.jupyter` | 執行 `.ipynb` 筆記本的核心引擎 |
| **Jupyter 快捷鍵** | `ms-toolsai.jupyter-keymap` | 整合 Jupyter 原生快捷鍵習慣 |
| **Jupyter 渲染器** | `ms-toolsai.jupyter-renderers` | 支援 Plotly、互動式表格等多媒體輸出 |
| **Python 核心環境** | `ms-python.python` | Python 語法高亮、核心 Kernel 自動辨識 |
| **Python 除錯器** | `ms-python.debugpy` | 斷點除錯與變數即時監視 |
| **Claude AI 助手** | `anthropic.claude-code` | Anthropic 官方 Claude 程式碼輔助工具 |
| **ChatGPT 擴充** | `openai.chatgpt` | OpenAI 官方 ChatGPT 對話與補全 |
| **Zoo Code 助手** | `zoocodeorganization.zoo-code` | 強大的多模型 AI 編程助手 (Zoo Code) |
| **Antigravity 助手** | `google.google-antigravity` | Google Antigravity 智慧輔助擴充套件 |

### B. 一鍵指令批次安裝
我們在 `scripts/` 目錄中準備好了一鍵安裝腳本 [`install_vscode_extensions.sh`](./scripts/install_vscode_extensions.sh)：

```bash
cd ~/hpc-tutorial/04-ai-developer-tools/scripts
bash install_vscode_extensions.sh
```

您也可以單獨安裝指定套件：
```bash
code-server --install-extension ms-toolsai.jupyter
code-server --install-extension zoocodeorganization.zoo-code
code-server --install-extension anthropic.claude-code
```

---

## 2. AI 命令行工具安裝：Antigravity CLI (agy) 與 OpenCode

除了圖形介面擴充套件，在 HPC 終端機環境中具備強大的 AI CLI 工具能大幅加速腳本編寫、排程自動化與除錯。

### A. OpenCode CLI
[OpenCode](https://opencode.ai) 是一個開源且高度模組化的終端機 AI 工具，原生支援多種 Provider（OpenAI 相容協議、Anthropic、Google 等）。

* **官方安裝指令**：
  ```bash
  curl -fsSL https://opencode.ai/install.sh | bash
  ```
* **安裝路徑**：`~/.opencode/bin/opencode`

### B. Antigravity CLI (`agy`)
Google DeepMind Antigravity CLI 專門用於多代理架構 (Agentic Coding)、專案推理與自動除錯。
* **二進位檔路徑**：`~/.local/bin/agy`
* **驗證指令**：
  ```bash
  agy --version
  ```

### C. 設定環境變數 PATH
請確保您的 `~/.bashrc` 中包含這兩個路徑：
```bash
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
```
*(執行 [`scripts/install_ai_cli.sh`](./scripts/install_ai_cli.sh) 可自動完成檢查與 PATH 寫入)*

---

## 3. OpenCode 國網中心設定檔診斷與修復報告

針對您提供的 `~/.config/opencode/opencode.json` 設定內容，我們進行了語法與架構診斷：

### ❌ 錯誤 1：尾隨逗號引發 JSON 語法錯誤 (Trailing Comma Syntax Error)
* **原始內容**：
  ```json
      "medusa-innser": {
        ...
      },  <-- 這裡多了一個逗號！
    },
    "model": "gemma-4-26B-A4B-it"
  ```
* **原因**：標準 JSON 規範嚴格禁止在最後一個屬性後面保留逗號（Trailing Comma）。這會直接導致 OpenCode 啟動時崩潰並拋出 `SyntaxError: Unexpected token '}' in JSON`。

### ❌ 錯誤 2：模型指定缺少 Provider 前綴
* **原始內容**：
  ```json
  "model": "gemma-4-26B-A4B-it"
  ```
* **原因**：在 OpenCode 的架構中，當使用自訂 Provider（如 `medusa-portal` 或 `medusa-inner`）時，模型全名必須包含 Provider 前綴，格式為 **`<provider-id>/<model-id>`**。  
* **修正後**：
  ```json
  "model": "medusa-inner/gemma-4-26B-A4B-it"
  ```
  *(若只填 `gemma-4-26B-A4B-it`，OpenCode 無法得知應將請求發送到哪一個端點)*

### 💡 筆誤建議：Provider 名稱標準化
* 原設定將名稱打為 `"medusa-innser"`（多了一個 `s`）。雖然技術上只要與模型前綴一致即可運作，但建議更正為語意明確的 `"medusa-inner"`。

---

## 4. 正確標準版 opencode.json 配置方案

設定檔放置於：`~/.config/opencode/opencode.json`。以下為修正且通過驗證的標準配置方案（範本位於 [`templates/opencode.json`](./templates/opencode.json)）：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "medusa-portal": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://portal.genai.nchc.org.tw/api/v1/",
        "apiKey": "YOUR_MEDUSA_PORTAL_KEY"
      },
      "models": {
        "gpt-oss-120b": { "name": "gpt-oss-120b" },
        "Devstral-2-123B-Instruct-2512": { "name": "Devstral-2-123B-Instruct-2512" },
        "Devstral-Small-2-24B-Instruct-2512": { "name": "Devstral-Small-2-24B-Instruct-2512" },
        "Ministral-3-14B-Instruct-2512": { "name": "Ministral-3-14B-Instruct-2512" },
        "Ministral-3-8B-Instruct-2512": { "name": "Ministral-3-8B-Instruct-2512" }
      }
    },
    "medusa-inner": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://inner-medusa.genai.nchc.org.tw/v1/",
        "apiKey": "YOUR_MEDUSA_INNER_KEY"
      },
      "models": {
        "gpt-oss-120b": { "name": "gpt-oss-120b" },
        "Thanos3.5-397B-A17B": { "name": "Thanos3.5-397B-A17B" },
        "Thanos3.5-397B-A17B-tasa": { "name": "Thanos3.5-397B-A17B-tasa" },
        "Mistral-Large-3-675B-Instruct-2512": { "name": "Mistral-Large-3-675B-Instruct-2512" },
        "MiniMax-M2.5": { "name": "MiniMax-M2.5" },
        "gemma-4-26B-A4B-it": { "name": "gemma-4-26B-A4B-it" },
        "gemma-4-31B-it": { "name": "gemma-4-31B-it" },
        "MiniMax-M3": { "name": "MiniMax-M3" },
        "Kimi-K3": { "name": "Kimi-K3" }
      }
    },
    "local-sglang": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://25a-hgpn004:8000/v1",
        "apiKey": "none"
      },
      "models": {
        "MiniMax-M2.7": { "name": "MiniMaxAI/MiniMax-M2.7" }
      }
    }
  },
  "model": "medusa-inner/gemma-4-26B-A4B-it"
}
```

---

## 5. 國網中心支援模型清單與場景推薦

國網中心 Medusa 平台提供了多元的開源大型語言模型（LLM），以下為各模型的特點與推薦用途：

| 模型代號 | 參數規模 / 架構 | 最佳適用情境 |
| :--- | :--- | :--- |
| **`gemma-4-26B-A4B-it`** | Google Gemma 最新 MoE 架構 | **日常 Coding、Bash 腳本編寫、輕量問答（預設推薦）** |
| **`gemma-4-31B-it`** | 31B Dense 密集模型 | 邏輯嚴密之演算法設計、技術文件摘要 |
| **`Devstral-2-123B-Instruct`** | 123B 專用代碼大模型 | 大型專案重構、複雜程式碼生成、除錯分析 |
| **`Mistral-Large-3-675B`** | 675B 超大規格模型 | 複雜推理、論文分析、高難度多步驟任務規劃 |
| **`Thanos3.5-397B-A17B`** | 397B MoE 旗艦模型 | 綜合型中文/多語言理解與學術研究輔助 |
| **`MiniMax-M2.5 / M3`** | 長文本推理模型 | 超長日誌分析、整份代碼庫閱讀 |

---

## 6. 實機測試與模型呼叫指令

### 1. 查詢所有已成功載入的模型
在終端機中執行：
```bash
opencode models
```
**輸出範例：**
```text
medusa-inner/gemma-4-26B-A4B-it
medusa-inner/gemma-4-31B-it
medusa-inner/gpt-oss-120b
medusa-inner/Mistral-Large-3-675B-Instruct-2512
medusa-portal/Devstral-2-123B-Instruct-2512
local-sglang/MiniMax-M2.7
```

### 2. 測試與模型對話
```bash
# 使用預設模型 (gemma-4-26B-A4B-it) 提問
opencode run "請以 Python 撰寫一個計算費波那契數列的函式"

# 臨時指定切換至 Devstral 模型
opencode run -m medusa-portal/Devstral-2-123B-Instruct-2512 "寫一個 Slurm 批次作業腳本範本"
```

---

## 7. AI Agent 專屬 HPC 治理規則：AGENTS.md 實務

當我們在 HPC 上使用 AI Agent（如 Claude Code、OpenCode、Antigravity 或 Cursor）時，預設情況下 AI 對超級電腦的多用戶環境與排程規則一無所知，常常會犯下致命錯誤：
* ❌ 企圖下達 `sudo apt install` 或修改 `/etc`（無 root 權限）。
* ❌ 在登入節點直接開 32 執行緒跑多行程（導致登入節點卡死被管理員鎖帳號）。
* ❌ 寫出不存在的 Slurm 分區名稱（如 `--partition=gpu`）。

### A. 什麼是 `AGENTS.md`？
`AGENTS.md` 是現代 AI 輔助開發的「系統守則文件」。只要將此檔案放在專案根目錄，所有主流 AI Agent 啟動時都會**主動讀取並嚴格遵守裡面的規範**！

### B. 創進一號專屬 AGENTS.md 範本
本專案已在根目錄配置了開箱即用的標準規範：[`AGENTS.md`](../AGENTS.md)。其核心規範包括：
1. **嚴禁 sudo**：明確告知 AI 這是多人 HPC，不可使用 root 指令。
2. **登入節點禮節**：耗時超過 5 分鐘或大於 4 核心之任務，強制要求 AI 改寫為 Slurm 批次腳本。
3. **儲存位置指引**：指示 AI 將大數據與虛擬環境建於 `/work1/$USER`，代碼放 `$HOME`。
4. **Slurm 寫作約束**：強制指定 `ct112` / `cf112` 分區，且執行內容第一行必加 `module purge`！

> [!TIP]
> 未來您在超級電腦上開展任何新科研專案時，只需將本範本複製到專案根目錄：
> ```bash
> cp ~/hpc-tutorial/AGENTS.md ~/your_project/AGENTS.md
> ```
> 您的 AI Agent 就會立刻變身為深諳國網超級電腦規矩的資深 HPC 專家！

---

## 8. 延伸整合：國網官方 Ollama 本地大模型部署方案

> 參考官方技術手冊：[創進一號 Ollama 部署與大模型應用手冊](https://man.twcc.ai/@f1-manual/ollama_guide)

除了使用國網中心集中式的 Medusa GenAI API 之外，創進一號官方手冊亦推薦研究人員在具備 GPU 的節點（如 `visual-dev` 或 Slurm GPU 佇列）透過 **Singularity 容器部署獨立的 [Ollama](https://ollama.com/) 服務**：

### A. 為什麼在 HPC 上使用本地 Ollama？
1. **數據隱私與資料安全**：敏感專利代碼或臨床未發表數據可在專屬節點 GPU 上本機推論，完全不出節點。
2. **無需外部 API Key**：不受外部額度或網路連線限制。
3. **原生相容 OpenAI 協議**：Ollama 啟動後在 `http://127.0.0.1:11434/v1` 提供標準 API，能直接與 Code-Server 的 AI 擴充套件（如 Continue、Zoo Code）或終端機的 OpenCode 無縫串接！

### B. 在 OpenCode 中無縫切換本地 Ollama
若您在節點上啟動了 Ollama 服務，只需在 `~/.opencode/opencode.json` 新增一組本地 Provider：

```json
{
  "provider": {
    "ollama_local": {
      "name": "Ollama Local GPU",
      "api_base": "http://127.0.0.1:11434/v1",
      "api_key": "ollama",
      "models": [
        "llama3.1:8b",
        "codellama:7b",
        "qwen2.5-coder:7b"
      ]
    }
  }
}
```
即可在 Code-Server 整合終端機中敲入 `opencode -p ollama_local`，直接使用地端專屬大模型！

---

## 9. 網路避坑提醒：no_proxy 排除國網內網端點 (進階選修)

> [!NOTE]
> **💡 初學者線性閱讀指引**：
> 在登入節點上開發或使用 OpenCode 時，系統可直接連通國網 Medusa 端點，**完全不需要設定任何 Proxy**。
> 本節是針對未來在第 07、08 章將任務派送至「計算節點」時的網路避坑備忘，**初讀此章時可直接跳過**！

在超級電腦環境中，當您配合 **第 07 章的計算節點 Proxy** 使用時，請務必注意：

* `portal.genai.nchc.org.tw`：為外部域名，通常可直接連線或走外網。
* `inner-medusa.genai.nchc.org.tw` 與 `25a-hgpn004`：為**國網中心內部直連端點**！

> [!WARNING]
> **嚴禁將內網請求導向對外 Proxy！**  
> 如果在計算節點設定了 `http_proxy`，必須確保 `no_proxy` 包含國網內網網段：
> ```bash
> export no_proxy="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,*.nchc.org.tw,*.genai.nchc.org.tw,25a-*"
> export NO_PROXY="${no_proxy}"
> ```
> 否則內部請求會被送往外網 Proxy 轉發，導致 `inner-medusa` 連線失敗（`504 Gateway Timeout` 或 `Host Unreachable`）。  
> *(第 07 章的 `set_compute_env.sh` 已經預設為您設定好此排除清單！)*

---

👉 **下一步**：進入 **[第 05 章：AI 輔助生醫管線 (FASTQ 質控登入節點實作)](../05-ai-assisted-bio-pipeline/)**，指揮剛設定好的 AI 助手編寫資料分析管線！
