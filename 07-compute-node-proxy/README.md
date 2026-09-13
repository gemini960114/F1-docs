# HPC 實戰指南：計算節點對外連網與安全 HTTP Proxy 建置

本教學手冊旨在解決高效能運算（HPC）環境中最常見的網路隔離問題：**計算節點（Compute Node）無法直接連通外網，導致無法下載 Hugging Face 模型、PyPI 套件、GitHub 程式庫或相依套件**。

本章節介紹如何透過登入節點（Login Node）建立輕量、高效且具備密碼資安防護的 HTTP/HTTPS Proxy 隧道。

---

## 📌 目錄 (Table of Contents)
- [1. 背景與核心問題](#1-背景與核心問題)
- [2. 代理架構與方案評估](#2-代理架構與方案評估)
- [3. 叢集內部真實網路拓撲 (以國網中心為例)](#3-叢集內部真實網路拓撲-以國網中心為例)
- [4. 資安關鍵防護：防止 ps aux 密碼洩漏](#4-資安關鍵防護防止-ps-aux-密碼洩漏)
- [5. 檔案結構與腳本說明](#5-檔案結構與腳本說明)
- [6. 快速開始 (Quick Start)](#6-快速開始-quick-start)
- [7. 在 Slurm 任務中使用 Proxy](#7-在-slurm-任務中使用-proxy)
- [8. 常見問題與除錯 (FAQ & Troubleshooting)](#8-常見問題與除錯-faq--troubleshooting)

---

## 1. 背景與核心問題

在標準的超級電腦與 HPC 叢集（如國網中心 Taiwania 叢集）架構中，基於資安與防火牆原則：
* **登入節點 (Login Node)**：配備外部對外網卡，可直接連線網際網路（但嚴禁直接跑大量運算）。
* **計算節點 (Compute Node)**：由排程系統（Slurm）管理，完全置於封閉內部網路中，**不具備直接連線外網的能力**。

### 常見錯誤症狀
當您在計算節點中執行下列操作時：
```bash
git clone https://github.com/...            # 卡住無回應，最後 Connection timed out
pip install transformers                     # 連線失敗或 Read timed out
python -c "from transformers import ......"  # 拋出 urllib3 / requests 網路連線錯誤
```
這是因為計算節點發送的對外封包直接被內網防火牆攔截。

---

## 2. 代理架構與方案評估

### 架構原理
我們在具有外網能力的登入節點（Login Node）上架設 HTTP/HTTPS CONNECT Proxy 服務，計算節點透過叢集內部高速網路將外網請求委派給登入節點轉發：

```
┌─────────────────────────────────────────────────────────────┐
│                    外網網際網路 (Internet)                   │
│        (Hugging Face, PyPI, GitHub, Docker Hub...)          │
└──────────────────────────────▲──────────────────────────────┘
                               │ (外網連線)
┌──────────────────────────────┴──────────────────────────────┐
│                    登入節點 (Login Node)                     │
│  - 執行 background proxy 服務 (監聽 10.200.160.1:8888)        │
│  - 支援 HTTP CONNECT 隧道安全穿透                            │
└──────────────────────────────▲──────────────────────────────┘
                               │ (叢集 InfiniBand 高速內網)
┌──────────────────────────────┴──────────────────────────────┐
│                    計算節點 (Compute Node)                   │
│  - Slurm 批次作業 / srun 互動終端                            │
│  - export http_proxy="http://user:pass@10.200.160.1:8888"   │
└─────────────────────────────────────────────────────────────┘
```

### 代理方案比較

| 方案 | 優點 | 缺點 / 挑戰 | 評估結論 |
| :--- | :--- | :--- | :--- |
| **SOCKS5 (SSH Dynamic)** | 內建 SSH 功能即可使用 | 許多 Python 套件、系統工具對 SOCKS5 支援不全，需額外安裝 `pysocks`。 | ⚠️ 相容性較差 |
| **Tinyproxy** | C 語言原生、老牌輕量 | PyPI 沒有此套件，必須依賴 Conda-forge 或自行編譯，安裝較重。 | ⚠️ 依賴 Conda |
| **`proxy.py` + `uv`** (本教學推薦) | **純 Python、毫秒級安裝、支援 HTTP CONNECT HTTPS 穿透、獨立虛擬環境不污染專案** | 需 Python 3.8+ (HPC 系統均已預裝) | ⭐ **最優推薦** |

---

## 3. 叢集內部真實網路拓撲 (以國網中心為例)

> [!WARNING]
> 許多網路文章範例習慣使用 `10.0.0.1` 作為 Proxy 伺服器位址，**但這是範例假 IP，在國網中心或一般叢集上並不存在**！

在登入節點上透過 `ip addr` 查詢可知，這台登入節點（`ilgn01`）對計算節點的真實內網 IP 為：
1. **InfiniBand 高速內網介面 (`ib0`)**：
   * **IP**: `10.200.160.1` (強烈推薦！走 InfiniBand 匯流排，延遲極低、頻寬極大)
2. **乙太網路介面 (`enp3s0`)**：
   * **IP**: `172.16.160.1`

因此，計算節點必須指定連線至 **`10.200.160.1:8888`**。

---

## 4. 資安關鍵防護：防止 ps aux 密碼洩漏

在共用叢集上，直接將帳號密碼寫在指令列是**嚴重的資安漏洞**：

```bash
# ❌ 危險寫法：
tmux new-session -d -s proxy "proxy --basic-auth myuser:MySecret123"
```
**為什麼危險？**  
Linux 的進程資訊儲存於 `/proc/<PID>/cmdline`。若未啟用 `hidepid`，同一台機器上的任何其他使用者只要下達 `ps -ef` 或 `ps aux`，就能直接看到您的指令與**明文密碼**！

### 🛡️ 本教學的安全解法
1. 將帳號與隨機密碼寫入個人檔案 `~/.proxy_auth`。
2. 將該檔案權限嚴格設為 **`chmod 600 ~/.proxy_auth`**（僅您本人可讀寫，他人無權查看）。
3. 透過 Python 啟動器 ([`start_proxy.py`](./scripts/start_proxy.py)) 於記憶體中讀取並載入，**完全不暴露在命令列參數中**。

驗證 `ps -ef` 輸出：
```text
c00cjz00  ... /home/c00cjz00/.venv-proxy/bin/python .../start_proxy.py
```
> 無論其他使用者如何用 `ps` 檢查，都看不到任何密碼！

---

## 5. 檔案結構與腳本說明

本教學模組包含開箱即用的自動化工具與範例：

```text
07-compute-node-proxy/
├── README.md                     # 本教學詳細說明手冊
├── scripts/
│   ├── setup_env.sh              # [1] 一鍵安裝 uv 與 proxy.py 專屬虛擬環境
│   ├── start_proxy.py            # [2] 安全啟動器 (記憶體載入密碼，防 ps 窺探)
│   ├── start.sh                  # [3] 在 Login Node 背景啟動 Proxy (tmux)
│   ├── stop.sh                   # [4] 在 Login Node 安全關閉 Proxy
│   └── set_compute_env.sh        # [5] 在 Compute Node 一鍵載入 Proxy 環境變數
└── examples/
    ├── test_connection.sh        # 測試連線 (Hugging Face / PyPI / GitHub)
    ├── download_hf_model.py      # 測試透過 Python 下載 Hugging Face 模型的 API
    └── job_test_proxy.slurm      # Slurm 批次作業完整範例腳本
```

---

## 6. 快速開始 (Quick Start)

### 第一步：在 Code-Server 整合式終端機啟動 Proxy
在 Code-Server 視窗中按下 **``Ctrl + ` ``** 展開整合式終端機（推薦點擊右上角 **`+`** 新開一個專用終端分頁）：
執行以下一鍵啟動腳本（若尚未安裝環境，它會自動為您建立 `~/.venv-proxy` 並生成安全密碼檔 `~/.proxy_auth`）：

```bash
cd ~/hpc-tutorial/07-compute-node-proxy/scripts
bash start.sh
```

**輸出結果範例：**
```text
========================================================
🎉 HTTP Proxy 成功於背景 (tmux) 啟動！
========================================================
登入節點內網 IP : 10.200.160.1
服務連接埠 (Port): 8888
認證帳號密碼    : c00cjz00:AbCd1234XyZ9
進程資安防護    : ✅ 已隱藏，ps 指令無法窺探密碼
--------------------------------------------------------
👉 在計算節點 (Compute Node) 請執行以下設定：

export http_proxy="http://c00cjz00:AbCd1234XyZ9@10.200.160.1:8888"
export https_proxy="http://c00cjz00:AbCd1234XyZ9@10.200.160.1:8888"
========================================================
```

### 第二步：在登入節點快速驗證
在登入節點測試本機連線是否成功：
```bash
curl -I -x http://$(cat ~/.proxy_auth)@127.0.0.1:8888 https://huggingface.co
```
> 若回傳 `HTTP/1.1 200 Connection established` 及 `HTTP/2 200`，即代表代理服務運作正常。

### 第三步：停止服務
運算任務結束後，隨時可在登入節點釋放資源：
```bash
bash ~/hpc-tutorial/07-compute-node-proxy/scripts/stop.sh
```

---

## 7. 在 Slurm 任務中使用 Proxy

在 HPC 中，計算節點通常透過 Slurm 排程執行。您可以透過兩種方式使用：

### 方式 A：互動式節點 (`srun` / `salloc`)
當您進入互動式運算節點後：
```bash
# 1. 載入 Proxy 環境變數 (自動從 ~/.proxy_auth 讀取帳密)
source ~/hpc-tutorial/07-compute-node-proxy/scripts/set_compute_env.sh

# 2. 測試連線能力
bash ~/hpc-tutorial/07-compute-node-proxy/examples/test_connection.sh

# 3. 執行需要外網的任務，例如下載模型或套件：
pip install transformers
python -c "from transformers import AutoTokenizer; AutoTokenizer.from_pretrained('bert-base-uncased')"
```

### 方式 B：批次作業提交 (`sbatch`)
在您的 `.slurm` 批次腳本中加入 `source .../set_compute_env.sh`：

```bash
#!/usr/bin/env bash
#SBATCH --job-name=download_models
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --output=job_%j.out

# 1. 載入 Proxy 設定
source ~/hpc-tutorial/07-compute-node-proxy/scripts/set_compute_env.sh

# 2. 執行訓練或下載工作
python train.py
```

您也可以直接提交測試範例確認：
```bash
cd ~/hpc-tutorial/07-compute-node-proxy/examples
sbatch job_test_proxy.slurm
```

---

## 8. 常見問題與除錯 (FAQ & Troubleshooting)

### Q1: 出現 `HTTP/1.1 407 Proxy Authentication Required`
* **原因**：計算節點未提供認證帳密，或帳號密碼不正確。
* **解法**：確認環境變數網址中包含 `帳號:密碼@`，或使用 `source set_compute_env.sh` 自動載入。

### Q2: 密碼含有特殊符號（例如 `@`、`:`、`$`）導致解析錯誤
* **原因**：URL 格式中 `@` 用於區隔認證與主機位址。
* **解法**：建議使用英數字組合（如 `start.sh` 自動生成的密碼），或在 URL 裡將符號轉換為 URL 編碼（例如 `@` 轉為 `%40`）。

### Q3: 節點間 MPI / 多機多卡分散式通訊卡住
* **原因**：NCCL 或 OpenMPI 在節點間通訊時，誤把內部內網 IP 導向 Proxy。
* **解法**：務必設定 `no_proxy` 環境變數排除叢集內網網段：
  ```bash
  export no_proxy="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12"
  export NO_PROXY="${no_proxy}"
  ```
  *(腳本 `set_compute_env.sh` 已經預設幫您加入此設定。⚠️ **注意**：切勿隨意加入 `*.nchc.org.tw` 萬用字元，否則連線至 `www.nchc.org.tw` 官網等公開網站時會因計算節點無外網直連而超時失敗)*

### Q4: 登入節點重新開機後服務中斷
* **說明**：登入節點為 Linux 實體機或 VM，若管理員維護重開機，tmux 工作階段會消失。重新連上登入節點後，只需再跑一次 `bash start.sh` 即可快速復原。

---

👉 **下一步**：進入 **[第 08 章：AI Agent 自動化排程 (將生醫管線派送至 Slurm)](../08-ai-agent-slurm-pipeline/)**，體驗 AI 如何將分析管線結合本章 Proxy 動態連網派送至計算節點！
