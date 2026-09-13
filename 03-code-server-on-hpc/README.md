# HPC 實戰指南：在超級電腦上運行 Code-Server (VS Code Web)

本教學手冊專為需要在國網中心（NCHC Taiwania / Open OnDemand）等 HPC 叢集上使用 **VS Code 瀏覽器介面 (Code-Server)** 的開發者設計。

本章節收錄並深入優化了您的兩個核心腳本：
1. **登入節點版本 (`~/start-code-server_v1.sh`)** ➔ 升級為 **tmux 背景常駐版本**。
2. **計算節點 Slurm 批次排程版本 (`~/sbatch_code_cpu.slurm`)** ➔ 診斷驗證並升級為**強固排程版本**。

---

## 📌 目錄 (Table of Contents)
- [1. 方案架構對比：登入節點 vs 計算節點](#1-方案架構對比登入節點-vs-計算節點)
- [2. 原始腳本深度剖析與改進](#2-原始腳本深度剖析與改進)
  - [A. 登入節點腳本 (start-code-server_v1.sh)](#a-登入節點腳本-start-code-server_v1sh)
  - [B. Slurm 批次排程腳本 (sbatch_code_cpu.slurm) 是否可以執行？](#b-slurm-批次排程腳本-sbatch_code_cpuslurm-是否可以執行)
- [3. 檔案結構說明](#3-檔案結構說明)
- [4. 實戰操作：登入節點 (Login Node) tmux 版](#4-實戰操作登入節點-login-node-tmux-版)
- [5. 實戰操作：計算節點 (Compute Node) Slurm 排程版](#5-實戰操作計算節點-compute-node-slurm-排程版)
- [6. Code-Server 瀏覽器日常操作與工作流程實務 (在瀏覽器中幹活)](#6-code-server-瀏覽器日常操作與工作流程實務-在瀏覽器中幹活)
  - [A. 整合式終端機 (Integrated Terminal) —— 超級電腦的中央指揮所](#a-整合式終端機-integrated-terminal--超級電腦的中央指揮所)
  - [B. 擴充套件市集：Open VSX vs 官方 Marketplace 與 .vsix 離線安裝](#b-擴充套件市集open-vsx-vs-官方-marketplace-與-vsix-離線安裝)
  - [C. 原始碼版本控制 (Git 面板) 視覺化操作](#c-原始碼版本控制-git-面板-視覺化操作)
  - [D. 互動式運算：Jupyter Notebook 與 /work1 虛擬環境綁定](#d-互動式運算jupyter-notebook-與-work1-虛擬環境綁定)
  - [E. 程式碼中斷點除錯 (Debugger) 實務](#e-程式碼中斷點除錯-debugger-實務)
  - [F. 高效快捷鍵與指令面板速查表](#f-高效快捷鍵與指令面板速查表)
- [7. 與第 07 章 Proxy 聯動：解決擴充套件無法下載問題 (進階選修)](#7-與第-07-章-proxy-聯動解決擴充套件無法下載問題-進階選修)
- [8. 常見問題與除錯 (FAQ)](#8-常見問題與除錯-faq)

---

## 1. 方案架構對比：登入節點 vs 計算節點

> [!NOTE]
> **💡 官方 OOD 原生「一鍵式 Code Server」vs 本章「自建版」對比**  
> 國網中心 Open OnDemand 門戶首頁本身提供了官方內建的「Code Server」互動式 App（點選「Interactive Apps」➔「Code Server」，設定 2 核心 / 8GB 記憶體即可一鍵啟動）。  
> * **官方一鍵版**：免寫任何腳本、圖形化勾選即開；但**受限於單次最長 8 小時自動終止**，且**同時間帳號僅能開啟 1 個互動式作業**。  
> * **本章自建登入節點版 (tmux 常駐)**：手動執行一次腳本，**不受 8 小時限制，只要主機不重開機即可持續長駐**，且不消耗互動式資源配額，是長期深度開發的最佳選擇。  
> * **本章自建計算節點版 (Slurm 排程)**：可自由自訂 Slurm 資源（例如申請 56 核心或 GPU），突破官方一鍵版固定規格的限制。  
> 讀者可視開發需求（快速體驗 vs 長期常駐/專屬算力）自由選擇！

> [!IMPORTANT]
> **💡 初學者推薦：請先使用「方案 A」！**  
> 剛進入超級電腦的新手，**強烈推薦一律使用「方案 A：登入節點 (tmux)」**！它具備即開即用 (1 秒啟動)、原生外網能力，且不消耗 Slurm SU 計畫點數。  
> 方案 B（計算節點 Slurm 排程）涉及作業調度語法；若您尚未學習 Slurm，**請安心先使用方案 A，待讀完第 06 章後再回頭參考方案 B**！

| 評估維度 | 方案 A：登入節點 (Login Node + tmux) | 方案 B：計算節點 (Compute Node + Slurm) |
| :--- | :--- | :--- |
| **適用場景** | 程式碼編寫、專案管理、文字編輯、提交 Slurm 作業 | 重度編譯、AI 模型訓練、大資料除錯、需專屬 CPU/GPU |
| **啟動速度** | **即開即用 (1 秒啟動)** | 需等待 Slurm 佇列調度 (數十秒至數分鐘) |
| **運行時長** | 只要伺服器不重開機，可長期常駐 | 受限於 Slurm Walltime（如 4 小時到期自動終止） |
| **運算資源** | 與其他使用者共用 CPU，**嚴禁執行重度運算** | 享有獨立專屬的 CPU 核心與獨立記憶體 |
| **外網連線** | 原生具備外網，可直接下載 Extension 與 git | 預設無外網（可結合本系列第 07 章 Proxy 連線） |

---

## 2. 原始腳本深度剖析與改進

### A. 登入節點腳本 (`start-code-server_v1.sh`)
* **原始運作機制**：在前景終端機直接啟動，使用 Python 隨機綁定 Port 並取得 `hostname -s`。
* **存在之小瑕疵**：
  1. 檔案末尾包含 Vim 複製殘留的字元（`~`）。
  2. 前台執行時若 SSH 斷線，Code-Server 即隨之中斷。
  3. `--bind-addr "${myhostname}:${myport}"`：若主機名稱對應到特定單一 IP，可能影響反向代理跨網卡連線。
* **優化改進 ([`scripts/start_code_server_tmux.sh`](./scripts/start_code_server_tmux.sh))**：
  * 加入 `tmux` 背景會話管理，即使登出 SSH，VS Code 仍然持續在背景運行。
  * 改綁定 `0.0.0.0:${PORT}`，確保所有網路介面（乙太網、InfiniBand）皆可順暢連通。
  * 啟動後自動把存取網址寫入 `~/.code-server-url.txt`，隨時可一鍵查詢。

---

### B. Slurm 批次排程腳本 (`sbatch_code_cpu.slurm`) 是否可以執行？

> [!TIP]
> **結論：這份腳本在國網中心叢集上「可以執行」！**  
> 我們透過 `sbatch --test-only` 實測驗證，帳號 `#SBATCH --account=GOV114022` 與分區 `#SBATCH --partition=ct112` **完全有效且通過排程器驗證**！

但是，原始腳本有 **3 個潛在地雷**需要修正，否則容易執行失敗：

1. **地雷一：輸出日誌目錄依賴 (`#SBATCH --output=logs/job-%j.out`)**  
   * **問題**：若您在某個沒有 `logs/` 資料夾的目錄下執行 `sbatch`，Slurm **不會自動建立目錄**，而是直接拋出 `_open_output_file: No such file or directory` 錯誤並強制取消作業！
   * **修復**：改為 `#SBATCH --output=%x-%j.out`，保證在任何目錄提交都能正確寫入。
2. **地雷二：重複的 Shebang (`#!/bin/bash` 出現 4 次)**  
   * **修復**：清理為單一行標準格式。
3. **地雷三：作業送出後不知道連線網址**  
   * **問題**：作業提交後被分派到計算節點（如 `icpnq101`），使用者必須手動等待並去 `cat logs/job-*.out` 才能找到網址。
   * **修復**：在腳本中將最新網址同步自動寫入 `~/.code-server-slurm-url.txt`，並提供專屬查詢指令 [`bash scripts/get_job_url.sh`](./scripts/get_job_url.sh)，點擊即可開啟！

---

## 3. 檔案結構說明

```text
03-code-server-on-hpc/
├── README.md                              # 本教學詳細操作指南
├── scripts/                               # 登入節點與輔助工具
│   ├── original_start_code_server.sh      # 原始登入節點腳本存檔
│   ├── start_code_server_tmux.sh          # [推薦] 登入節點 tmux 背景常駐啟動腳本
│   ├── stop_code_server.sh                # 登入節點服務關閉腳本
│   ├── get_job_url.sh                     # 一鍵查詢正在運行的 Slurm 作業網址
│   └── password_setup.sh                  # 安全密碼設定工具 (設定 chmod 600)
└── slurm/                                 # 計算節點 Slurm 排程腳本
    ├── original_sbatch_code_cpu.slurm     # 原始 Slurm 腳本存檔
    └── sbatch_code_cpu.slurm              # [推薦] 修正日誌路徑與網址自動導出的排程腳本
```

---

## 4. 實戰操作：登入節點 (Login Node) tmux 版

### 步驟 1：啟動服務
在登入節點（`ilgn01`）執行：
```bash
cd ~/hpc-tutorial/03-code-server-on-hpc/scripts
bash start_code_server_tmux.sh
```

**輸出範例：**
```text
========================================================
🎉 Code-Server 已成功於背景 (tmux) 啟動！
========================================================
登入節點主機   : ilgn01
服務連接埠     : 41253
登入密碼       : (已由 ~/.code-server-password 載入)
code-server 版本: 4.137.0
--------------------------------------------------------
🌐 國網中心 OOD 存取網址 (請於瀏覽器開啟):
👉 https://f1-stn01.nchc.org.tw/rnode/ilgn01/41253/?folder=/home/c00cjz00
========================================================
```

### 步驟 2：登入與使用
1. 直接在瀏覽器點擊上方輸出的網址。
2. 輸入 `~/.code-server-password` 中的密碼，即可進入完整的 VS Code 介面！

### 步驟 3：管理與關閉
```bash
# 查看即時視窗 / 除錯
tmux attach -t code-server
# (脫離 tmux 視窗回到命令列: 先按 Ctrl+B，放開後按 D)

# 關閉服務
bash stop_code_server.sh
```

---

## 5. 實戰操作：計算節點 (Compute Node) Slurm 排程版

### 步驟 1：提交 Slurm 批次作業
```bash
cd ~/hpc-tutorial/03-code-server-on-hpc/slurm
sbatch sbatch_code_cpu.slurm
```
**輸出範例：**
```text
Submitted batch job 1073740
```

### 步驟 2：一鍵查詢連線網址
等待數秒讓作業分派啟動後，直接執行查詢工具：
```bash
bash ~/hpc-tutorial/03-code-server-on-hpc/scripts/get_job_url.sh
```
**輸出範例：**
```text
========================================================
🔍 查詢正在運行的 code-server 作業...
========================================================
   JOBID  PARTITION         NAME    STATE       TIME NODELIST(REASON)
 1073740      ct112  code-server  RUNNING       0:12 icpnq101
--------------------------------------------------------
📋 最新排程產生的 OOD 連線網址:
Job ID     : 1073740
Node       : icpnq101
Port       : 39821
OOD 網址 (主要): https://f1-stn01.nchc.org.tw/rnode/icpnq101/39821/?folder=/home/c00cjz00
OOD 網址 (備援): https://f1-stn02.nchc.org.tw/node/icpnq101/39821/?folder=/home/c00cjz00
========================================================
```
點擊終端機產生的連結即可進入擁有 **4 核心 CPU 專屬運算資源** 的 VS Code 環境！

### 步驟 3：工作結束後取消作業
```bash
scancel 1073740
# 或取消所有個人的 code-server 作業
scancel -u $(whoami) -n code-server
```

---

## 6. Code-Server 瀏覽器日常操作與工作流程實務 (在瀏覽器中幹活)

> [!IMPORTANT]
> **🚀 典範轉移：從這一刻起，徹底告別外部 SSH 終端機視窗！**  
> 一旦您透過瀏覽器進入 Code-Server，您的本機終端機軟體（PuTTY、MobaXterm、Mac Terminal、Windows PowerShell 等）**已經可以全部關閉**！  
> 從本章開始，整個超級電腦的日常研發工作——包含**寫程式、斷點除錯、運行 Jupyter 筆記本、管理 Git、安裝 AI 助手、提交 Slurm 排程、監控任務輸出**，**全部都在這個 Code-Server 瀏覽器分頁中完成**。

### A. 整合式終端機 (Integrated Terminal) —— 超級電腦的中央指揮所

* **快捷鍵召喚**：按下 **``Ctrl + ` ``**（反引號，與 `~` 同鍵）隨時展開或收合底部的整合式終端機。
* **真實節點環境**：這個終端機直接運行在 HPC 登入節點（`ilgn01`），具備完整的個人權限與 Linux Bash 環境。任何在終端機可敲的指令（如 `ls`, `uv`, `sbatch`, `squeue`），在這裡完全一致！
* **分頁與分割窗格 (Split Terminal)**：
  * 點擊終端機右上角 **`+`** 可新增多個終端分頁。
  * 點擊 **`|`** 圖示或按下快捷鍵 **`Ctrl + Shift + 5`**，可將終端機左右對半切割！
  * **💡 專家推薦的高效工作三分割配置**：
    1. **終端分頁 1（左側）**：日常代碼執行與互動測試（如 `uv run python main.py`）。
    2. **終端分頁 2（右側）**：Slurm 任務派送與日誌串流（提交 `sbatch`、需要時手動單次執行 `squeue -u $USER`、或使用 `tail -f slurm-*.out` 追蹤輸出）。
    3. **終端分頁 3（背景）**：常駐輔助服務（例如第 07 章的內網 Proxy 隧道）。

```text
┌───────────────────────────────────────┬───────────────────────────────────────┐
│ [Terminal 1: 開發與除錯]               │ [Terminal 2: 排程派送與日誌串流]      │
│ (my_env) [c00cjz00@ilgn01 ~]$         │ [c00cjz00@ilgn01 ~]$ sbatch job.slurm │
│ uv run python analyze.py              │ Submitted batch job 10738             │
│ [INFO] Processed 1000 records.        │ [c00cjz00@ilgn01 ~]$ tail -f 10738.out│
└───────────────────────────────────────┴───────────────────────────────────────┘
```

> [!WARNING]
> **⚠️ 國網中心官方鐵律：嚴禁使用 `watch` 或迴圈搭配 `squeue`！**  
> 官方「初次使用須知」明文嚴格規定：**「禁用 watch 指令或程式迴圈搭配 squeue 的做法，這會增加排程系統負擔。建議改用電子郵件通知機制。」**  
> 想要獲知任務進度，請在 Slurm 腳本中加入 `#SBATCH --mail-type=END,FAIL --mail-user=your_email@domain.com`，或在需要確認時手動執行一次 `squeue -u $USER` 即可，**切勿使用 watch 進行無休止的高頻輪詢**！

---

### B. 擴充套件市集：Open VSX vs 官方 Marketplace 與 .vsix 離線安裝

* **底層市集差異**：微軟官方 Visual Studio Marketplace 受其條款限制，僅授權給微軟官方桌面版軟體。Code-Server 預設連接由 Eclipse 基金會維護的開放開源市集 **[Eclipse Open VSX (open-vsx.org)](https://open-vsx.org/)**。
* **原生相容熱門套件**：
  * Python、Pyright、Jupyter、GitLens、Docker、Clangd、Markdown All in One 等知名套件均已收錄於 Open VSX。
  * 在左側活動列點擊 **Extensions 圖示 (`Ctrl + Shift + X`)** 即可直接搜尋並一鍵安裝！
* **微軟專有套件限制與開源替代方案**：
  * **C/C++**：微軟官方 `ms-vscode.cpptools` 受授權限制。推薦改用 LLVM 官方出品的 **clangd (`llvm-vs-code-extensions.vscode-clangd`)**，其語法補全速度更快且記憶體佔用更低。
  * **Python IntelliSense**：推薦改用開源相容的 **Pyright (`ms-pyright.pyright`)** 搭配極速 linter **Ruff (`charliermarsh.ruff`)**。
* **手動離線安裝 `.vsix` 技巧**：
  若特定套件在 Open VSX 搜尋不到，您可以手動安裝：
  1. **圖形化拖曳**：在個人電腦上下載該套件的 `.vsix` 檔，直接將檔案拖曳至 Code-Server 視窗中；或在 Extensions 面板右上角點擊 **`...` (Views and More Actions) ➔ 「Install from VSIX...」**，選取該檔案。
  2. **終端機指令安裝**：在 Code-Server 整合終端機中執行：
     ```bash
     code-server --install-extension /path/to/my-extension.vsix
     ```

---

### C. 原始碼版本控制 (Git 面板) 視覺化操作

* **圖形化 Git 面板**：點擊左側活動列的 **Source Control 圖示 (`Ctrl + Shift + G`)**。
* **視覺化雙欄比對 (Diff View)**：
  * 點擊任何已修改的檔案，編輯器立即開啟左右對比視窗（左為 Git HEAD 原版，右為目前編輯版）。
  * 綠色區塊代表新增、紅色代表刪除，比在黑底終端機看文字 `git diff` 更加清晰安全。
* **一鍵暫存與提交 (Stage & Commit)**：
  * 滑鼠懸浮在修改的檔案上，點擊 **`+`** 即可暫存（等同 `git add`）。
  * 在上方訊息框輸入 Commit 說明，按下 **`Ctrl + Enter`**（或點擊上方勾勾）即可完成提交。
* **與 GitHub 綁定免密碼推播**：
  在 Code-Server 整合終端機中生成金鑰並加入 GitHub：
  ```bash
  ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519 -N ""
  cat ~/.ssh/id_ed25519.pub  # 複製公鑰至 GitHub Settings -> SSH and GPG keys
  ```
  設定完成後，日後只要點擊 Code-Server 左下角的 **「Sync Changes」** 雲端圖示，就能一鍵將程式碼 Push 到 GitHub！

---

### D. 互動式運算：Jupyter Notebook 與 /work1 虛擬環境綁定

科研工作中最依賴互動式探索（EDA）與圖表繪製。在 Code-Server 中：

1. **建立 Notebook**：按 `Ctrl + Shift + P` 輸入 `Create: New Jupyter Notebook`，或在檔案樹右鍵建立 `analysis.ipynb`。
2. **綁定 Python Kernel**：
   * 點擊 Notebook 右上角的 **「Select Kernel」** ➔ **「Python Environments...」**。
   * 若清單未自動列出，點擊 **「Find Python Interpreter...」**，貼上第 01 章由 `uv` 建立在高速儲存區的 Python 直譯器絕對路徑：
     ```text
     /work1/c00cjz00/my_project_env/bin/python
     ```
3. **網頁即時互動渲染**：
   * 執行含有 `matplotlib`、`seaborn` 或 `plotly` 的單元格時，高解析度圖表直接在瀏覽器下方呈現。
   * **優勢**：完全不需要笨重的 X11 Forwarding，也不需要手動 `scp` 把圖片下載到本地電腦才能檢視！

---

### E. 程式碼中斷點除錯 (Debugger) 實務

不需要再靠 `print()` 盲目猜錯！Code-Server 具備與桌面端 100% 相同的除錯引擎：

1. **開啟除錯面板**：點擊左側 **Run and Debug 圖示 (`Ctrl + Shift + D`)**。
2. **自動配置除錯範本**：點擊「create a launch.json file」，選擇 **Python Debugger**，或直接在專案根目錄 `.vscode/launch.json` 寫入：
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Python: Current File",
         "type": "debugpy",
         "request": "launch",
         "program": "${file}",
         "console": "integratedTerminal"
       }
     ]
   }
   ```
3. **實戰斷點**：
   * 在程式碼行號左側點擊，產生**紅色圓點（Breakpoint）**。
   * 按下 **`F5`** 啟動除錯，程式將精準暫停在該行。
   * 在左側 **VARIABLES** 檢視變數內容、在 **WATCH** 加入運算式監視，並透過 **`F10`（單步步過）** 與 **`F11`（單步步入）** 進行精確除錯。

---

### F. 高效快捷鍵與指令面板速查表

| 快捷鍵 | 動作名稱 | 實務場景 |
| :--- | :--- | :--- |
| **`Ctrl + Shift + P`** (或 `F1`) | **指令面板 (Command Palette)** | 搜尋並執行任何 VS Code 命令（如 Reload Window、格式化檔案） |
| **`Ctrl + P`** | **快速開啟 (Quick Open)** | 打檔案名稱快速跳轉檔案，不必在目錄樹一層層翻找 |
| **``Ctrl + ` ``** | **切換整合式終端機** | 隨時喚出登入節點命令列，打完指令後一鍵收回 |
| **`Ctrl + B`** | **切換側邊欄 (Toggle Sidebar)** | 隱藏左側檔案樹，最大化程式碼與文字編輯視窗 |
| **`Ctrl + Shift + F`** | **全域搜尋 (Global Search)** | 在整個工作區中搜尋特定函式或關鍵字，支援正規表達式 |
| **`Alt + Up / Down`** | **整行移動 (Move Line)** | 將游標所在的程式碼行上下平移，重構代碼極快 |
| **`Ctrl + /`** | **快速註解 (Toggle Comment)** | 將選取的單行或多行程式碼快速加入/解除 `#` 或 `//` 註解 |

---

## 7. 與第 07 章 Proxy 聯動：解決擴充套件無法下載問題 (進階選修)

> [!NOTE]
> **💡 初學者線性閱讀指引**：
> 本章推薦在**「登入節點」**以 `tmux` 執行 Code-Server（方案 A），**登入節點原生具備外網連線能力，無需任何 Proxy 設定即可直接下載擴充套件**！
> 此小節之「計算節點掛載 Proxy」屬於**進階延伸架構**，若您初次學習，**此處可直接跳過**，待閱讀至第 07 章學會 Proxy 建置後再回頭查閱即可。

若使用**計算節點**的 Code-Server，預設因為沒有外網，打開 Extension 商店時會無法搜尋或下載套件。

### 自動聯動機制
在優化後的 [`sbatch_code_cpu.slurm`](./slurm/sbatch_code_cpu.slurm) 中，已經內建了自動偵測第 07 章 Proxy 的邏輯：
```bash
# 若第 07 章 Proxy 腳本存在，自動載入環境變數
PROXY_ENV="${HOME}/hpc-tutorial/07-compute-node-proxy/scripts/set_compute_env.sh"
if [ -f "${PROXY_ENV}" ]; then
    source "${PROXY_ENV}" 2>/dev/null || true
fi
```
只要您的 Login Node 有執行第 07 章的 Proxy，計算節點上的 VS Code 就能**自動擁有外網能力**，順暢下載 Extensions、使用 GitHub Copilot 或執行 `git pull/push`！

---

## 8. 常見問題與除錯 (FAQ)

### Q1: 打開網頁顯示 `502 Bad Gateway` 或 `Connection Refused`
* **原因**：Code-Server 仍在初始化中，或是綁定到 `localhost` 導致反向代理連不上。
* **解法**：請確保使用優化後的腳本（綁定 `0.0.0.0`），並等待 3~5 秒讓 Node.js 完全啟動後再重整網頁。

### Q2: 忘記密碼或想修改密碼
* 執行內建工具重新生成密碼：
  ```bash
  # 自動隨機生成新密碼
  bash ~/hpc-tutorial/03-code-server-on-hpc/scripts/password_setup.sh

  # 或指定自訂密碼
  bash ~/hpc-tutorial/03-code-server-on-hpc/scripts/password_setup.sh MyNewPassword999
  ```

### Q3: Slurm 作業狀態一直處於 `PD` (Pending)
* **原因**：分區資源忙碌中正在排隊。
* **查看原因**：執行 `squeue -u $(whoami)`，查看 `NODELIST(REASON)` 欄位（例如 `Resources` 或 `Priority`）。

---

👉 **下一步**：進入 **[第 04 章：AI 開發工具鏈與 OpenCode 國網模型配置](../04-ai-developer-tools/)**，在剛建好的 VS Code 中安裝擴充套件與配置國網 Medusa 地端大模型！
