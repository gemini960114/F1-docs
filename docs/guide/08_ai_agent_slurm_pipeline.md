# HPC 實戰指南：AI Agent 自動化排程 — 將生醫管線派送至 Slurm 計算節點 (雙實戰案例)

本教學手冊為 **HPC 實戰教學系列** 的最終章與集大成之作。本章節將展示如何引導 **AI Agent（Claude Code / Zoo Code / OpenCode）**，將前述章節在登入節點執行的互動式生醫分析管線，重構並封裝為專業的 **Slurm 批次排程作業**，同時完整實作 **「事前下載離線運算」** 與 **「掛載 HTTP Proxy 動態下載」** 兩種關鍵生產環境架構。

---

## 📌 目錄 (Table of Contents)
- [1. 為什麼要將腳本派送至 Slurm 佇列？](#1-為什麼要將腳本派送至-slurm-佇列)
- [2. 請 AI Agent 自動重構 Slurm 腳本 (Prompt 技巧)](#2-請-ai-agent-自動重構-slurm-腳本-prompt-技巧)
- [3. 兩大運算架構對比：離線運算 vs 動態 Proxy](#3-兩大運算架構對比離線運算-vs-動態-proxy)
- [4. 實戰案例 A：事前資料下載 / 純離線運算模式](#4-實戰案例-a事前資料下載--純離線運算模式)
- [5. 實戰案例 B：掛載 HTTP Proxy / 即時動態下載模式](#5-實戰案例-b掛載-http-proxy--即時動態下載模式)
- [6. 結果檢驗與成果匯總](#6-結果檢驗與成果匯總)
- [7. HPC 實戰全系列 8 大課程完結總結](#7-hpc-實戰全系列-8-大課程完結總結)

---

## 1. 為什麼要將腳本派送至 Slurm 佇列？

在第 5 章中，我們示範了在登入節點執行小量 FASTQ 質控。然而：
* 登入節點是多人共用，不可佔用過量 CPU 或跑長時間運算。
* 只有將任務打包送入 **Slurm 計算節點 (Compute Node)**，才能申請 **多核心 CPU（如 4~112 核心）**、**大容量記憶體** 與 **GPU 加速卡**，實現數十至數百個樣品的高度平行處理！

---

## 2. 請 AI Agent 自動重構 Slurm 腳本 (Prompt 技巧)

在 **Code-Server 瀏覽器工作台** 中，開啟您安裝好的 AI 助手（如 Claude Code、Zoo Code 或在整合式終端機運行 OpenCode）。AI 會自動讀取專案根目錄的 `AGENTS.md` 規範，您只需輸入具體的重構需求提示詞：

```text
你是一位熟悉超級電腦 Slurm 排程器與生物資訊分析的專家。
我原本在登入節點有一個執行 FASTQ 質控分析（FastQC + MultiQC）的互動腳本。
現在我希望將這套流程改由 Slurm 佇列派送到計算節點執行。

請幫我編寫兩個版本的 Slurm 批次作業腳本（符合國網中心規格，使用 #SBATCH --account=GOV114022 與 --partition=ct112）：
1. 案例 A：事前資料下載 / 離線運算模式 (資料已在登入節點就緒，計算節點純內網多核平行處理)。
2. 案例 B：掛載 HTTP Proxy 動態下載模式 (計算節點自動掛載第 07 章 Proxy 10.200.160.1:8888 即時抓取遠端資料並質控)。
```
*(完整提示詞可參考 [`prompts/ai_prompt_convert_to_slurm.md`](https://github.com/gemini960114/f1-docs/blob/main/08-ai-agent-slurm-pipeline/prompts/ai_prompt_convert_to_slurm.md))*

> [!TIP]
> **Code-Server 工作流優勢**：  
> AI 產生的腳本會直接呈現在 Code-Server 編輯器中，您可以立即使用程式碼比對檢視修改，並在下方的整合式終端機一鍵輸入 `sbatch` 提交作業！


---

## 3. 兩大運算架構對比：離線運算 vs 動態 Proxy

```text
【架構 A：事前下載 / 離線運算】
[登入節點] ──(外網下載 FASTQ)──> [共用家目錄 NFS/GPFS]
                                           │
[計算節點] <──(純內網高速讀取資料並多核分析)───┘

【架構 B：掛載 HTTP Proxy / 動態下載】
[登入節點] ──(背景常駐 proxy.py 10.200.160.1:8888)──> [外部網際網路]
       ▲                                                    ▲
       │ (InfiniBand 內網 Proxy 隧道)                         │
[計算節點] ──(即時下載 FASTQ 數據並立即進行質控處理)────────────┘
```

| 評估項目 | 案例 A：事前下載離線運算 | 案例 B：掛載 HTTP Proxy 動態下載 |
| :--- | :--- | :--- |
| **外部網路需求** | 計算節點完全不需要外網連線 | 計算節點透過登入節點 Proxy 穿透連網 |
| **資料準備時機** | 提交 Slurm 作業前已完整就緒 | Slurm 作業開始執行時由節點內部動態拉取 |
| **最佳適用場景** | 大規模長期定序專案、固定生物資料庫分析 | 自動化端到端 ETL、外部即時 API 抓取、容器/模型下載 |
| **網路依賴度** | ⭐ 零依賴，穩定度最高 | 依賴登入節點 Proxy 服務常駐 |

---

## 4. 實戰案例 A：事前資料下載 / 純離線運算模式

### 步驟 1：在登入節點準備好資料
在登入節點執行下載腳本，將資料存入共享目錄：
```bash
cd ~/hpc-tutorial/08-ai-agent-slurm-pipeline/case_a_offline
bash 01_download_on_login_node.sh
```

### 步驟 2：提交純離線 Slurm 計算作業
```bash
sbatch 02_submit_offline_qc.slurm
```
**Slurm 執行腳本重點解密**：
* 申請 4 個 CPU 核心 (`--cpus-per-task=4`)。
* 使用 `%x-%j.out` 避免目錄相依性。
* 計算節點從共用儲存目錄讀取 FASTQ，進行多執行緒 FastQC 與 MultiQC 匯總。

---

## 5. 實戰案例 B：掛載 HTTP Proxy / 即時動態下載模式

此模式示範計算節點如何直接連動 **第 07 章的 HTTP Proxy**，在無外網實體網卡的計算節點上，動態穿透抓取遠端資料！

### 步驟 1：確保登入節點的 Proxy 服務運行中
若尚未啟動，請在登入節點啟動第 07 章的 Proxy：
```bash
bash ~/hpc-tutorial/07-compute-node-proxy/scripts/start.sh
```

### 步驟 2：提交動態下載與質控作業
```bash
cd ~/hpc-tutorial/08-ai-agent-slurm-pipeline/case_b_proxy
sbatch run_proxy_pipeline.slurm
```

**Slurm 核心關鍵程式碼：**
```bash
# 1. 載入第 07 章的 Proxy 設定 (自動讀取個人密碼檔與內網 IP)
source ~/hpc-tutorial/07-compute-node-proxy/scripts/set_compute_env.sh 10.200.160.1 8888

# 2. 計算節點內部透過 Proxy 直接向外網下載資料
curl -sSL "https://data.qiime2.org/..." -o dynamic_sample.fastq.gz

# 3. 下載完成後立即啟動 FastQC 與 MultiQC
multiqc fastqc_out/ -o multiqc_out/
```

---

## 6. 結果檢驗與成果匯總

作業提交後，可透過第 06 章介紹的指令監控狀態：
```bash
squeue -u $(whoami)
```
當作業狀態自 `R` (Running) 結束後，即可檢視由計算節點產生的成果：
```bash
# 案例 A 產物:
cat ~/hpc-tutorial/08-ai-agent-slurm-pipeline/case_a_offline/qc_offline-*.out

# 案例 B 產物:
cat ~/hpc-tutorial/08-ai-agent-slurm-pipeline/case_b_proxy/qc_proxy-*.out
```

產生的 `multiqc_report.html` 同樣可藉由第 02 章與第 05 章的 `view_multiqc_report.sh` 透過 OOD 反向代理在瀏覽器中直接點擊預覽！

---

## 7. HPC 實戰全系列 8 大課程完結總結

恭喜您！至此整個 **HPC 實戰教學系列手冊** 已建立起完整、成體系且高度模組化的 8 大核心章節：

```
┌─────────────────────────────────────────────────────────────┐
│                 HPC 實戰教學系列手冊 (全 8 章)               │
├─────────────────────────────────────────────────────────────┤
│  01. 創進一號登入與雙因子認證 (SSH 連線、IDExpert 2FA、DTN) │
│  02. 網頁服務反向代理 (OOD 子路徑、Port 轉發、防 SIGTTIN 死鎖) │
│  03. 超級電腦運行 Code-Server (VS Code 網頁版、tmux 背景常駐)│
│  04. AI 開發工具鏈整合 (VS Code 套件、agy、OpenCode 國網模型)│
│  05. AI 輔助生醫管線 (FASTQ 下載與 FastQC/MultiQC 登入節點實作)│
│  06. Slurm 語法精講與超級電腦作業調度實務 (分區規格、陣列作業)│
│  07. 計算節點對外連網 (HTTP Proxy + 密碼防窺資安防護)         │
│  08. AI Agent 自動化排程 (將生醫管線派送至 Slurm：離線 vs Proxy)│
└─────────────────────────────────────────────────────────────┘
```

這 8 門課程由淺入深，從**安全遠端登入**、**Web 介面構建**，到全面進駐 **Code-Server 瀏覽器工作台**；在瀏覽器中完成 **AI 開發環境配置**、**生醫大數據分析原型**，並作為中央調度所指揮 **Slurm 高效能平行計算** 與 **網路隔離安全穿透**，為國網中心超級電腦上的研究與開發提供了最具實戰價值的現代化典範！
