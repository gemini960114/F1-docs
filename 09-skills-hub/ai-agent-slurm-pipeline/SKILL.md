---
name: ai-agent-slurm-pipeline
description: >-
  Comprehensive guide and workflow engine for AI Agents to automatically refactor interactive
  shell/Python scripts into production-ready Slurm batch jobs on HPC clusters (NCHC Forerunner 1 / f1).
  Covers the architectural decision between pure offline execution vs dynamic compute-node HTTP proxy,
  automated dependency chaining (`--dependency=afterok:`), multi-step pipeline decomposition,
  strict error handling (`set -euo pipefail`), and pre-flight validation.
---

# AI Agent Slurm Pipeline Refactoring Skill (自動化排程管線專家)

本技能指導 AI Agent 如何將使用者在終端機或 Code-Server 內手動執行的**互動式腳本（如生醫質控、資料前處理、機器學習訓練）**，自動重構為符合超級電腦規範的 **高強固性 Slurm 批次排程管線**。

---

## 🎯 核心能力與觸發時機

當使用者提出以下需求時觸發本技能：
1. **管線重構**：「把我在 Code-Server 終端機跑的這段腳本改寫成可以在計算節點跑的 Slurm 排程。」
2. **網路架構抉擇**：「我的程式在計算節點需要下載外部檔案或模型，該怎麼辦？」
3. **多階段相依排程**：「我有步驟一（下載）、步驟二（計算）、步驟三（匯總），如何用 Slurm 自動串接？」

---

## 🏗️ 第一部分：兩大運算架構決策樹 (Architecture Decision Tree)

在重構腳本前，AI 必須評估該運算是否需要外部網路連線，並引導使用者選擇最佳架構：

```text
               運算任務是否需要連線外網？
                      │
         ┌────────────┴────────────┐
        否                        是
         ▼                         ▼
   【架構 A：純離線運算】       【架構 B：動態 HTTP Proxy】
   - 資料已預先下載在共用儲存區   - 計算節點無原生外網
   - 不依賴登入節點服務          - 需掛載登入節點之安全 HTTP Proxy
   - 適合大規模、高穩定運算      - 適合需即時下載資料、模型或套件的管線
```

### 1. 架構 A：事前下載 / 純離線運算模式 (Pre-Staged Offline)
* **核心哲學**：重度計算與檔案傳輸徹底解耦。在登入節點完成 `git clone`、`wget` 或資料下載；計算節點僅讀取本機磁區（如 `/work1`）純離線運算。
* **優點**：極致穩定，計算節點 100% 離線，完全不受網路抖動或登入節點重開機干擾。
* **標準腳本關鍵特徵**：
  * 不需要設定任何 proxy 變數。
  * 專注於多執行緒核心配置與路徑檢查。

### 2. 架構 B：動態掛載 HTTP Proxy 運算模式 (Dynamic Proxy)
* **核心哲學**：利用本手冊第 07 章建立的登入節點 Tinyproxy（例如 `10.200.160.1:8888`），在計算節點啟動時自動載入認證與環境變數，讓計算節點具備對外連網能力。
* **適用場景**：需要於執行當下即時拉取 Hugging Face 模型、動態下載 FASTQ、或調用外部 API 的工作流。
* **標準腳本關鍵特徵**：
  * 在執行運算前載入 `set_compute_env.sh`：
    ```bash
    PROXY_ENV="${PROXY_ENV:-$HOME/.agents/skills/compute-node-proxy/scripts/set_compute_env.sh}"
    if [ -f "$PROXY_ENV" ]; then
        source "$PROXY_ENV"
    fi
    ```
  * 必須設置 `no_proxy` 排除叢集內網主機（`localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12`），避免內部通訊被誤轉送。注意切勿隨意加入 `*.nchc.org.tw` 避免公開網站直連逾時。

---

## 🛡️ 第二部分：AI 重構 Slurm 腳本之品質標準 (Quality Checklist)

AI Agent 產生之 Slurm 腳本必須 100% 通過以下安全檢驗：

1. **帳號與分區合規**：
   - 包含有效的 `#SBATCH --account=<wallet_PROJECT_ID>`。
   - 選擇登入節點可提交的合法分區（如 `ct112`、`cf112`、`development`），嚴禁誤用 `vscode` 或 `visual`。
2. **嚴格錯誤攔截**：
   - 腳本頂部加入 `set -euo pipefail`。任一指令出錯立即退出，嚴禁在錯誤狀態下繼續燒點數。
3. **無目錄依賴之日誌命名**：
   - 一律採用 `#SBATCH --output=%x-%j.out` 與 `#SBATCH --error=%x-%j.err`，嚴禁寫死不存在的 `logs/` 目錄。
4. **資源與環境診斷資訊**：
   - 腳本開頭輸出 `date`、`hostname`、`SLURM_JOB_ID`、`SLURM_CPUS_PER_TASK`。
5. **多核心自動綁定**：
   - 將軟體內部執行緒參數（如 `-t`、`-@`、`--threads`、`--cpus`）直接與 `${SLURM_CPUS_PER_TASK}` 變數綁定。

---

## 🔗 第三部分：自動化相依排程管線 (Pipeline Chaining)

當分析流程包含多個前後相依的步驟時，AI 應指導使用者使用 `--dependency=afterok:<job_id>` 建立全自動化流水線：

```bash
#!/bin/bash
# submit_pipeline.sh: 一鍵送出相依流水線
set -e

echo "1. 送出步驟一：資料前處理作業..."
JOB1=$(sbatch --parsable step1_download.slurm)
echo "   ➔ 步驟一 Job ID: $JOB1"

echo "2. 送出步驟二：核心重度計算 (依賴步驟一成功完成)..."
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 step2_compute.slurm)
echo "   ➔ 步驟二 Job ID: $JOB2"

echo "3. 送出步驟三：報告整合與清理 (依賴步驟二成功完成)..."
JOB3=$(sbatch --parsable --dependency=afterok:$JOB2 step3_report.slurm)
echo "   ➔ 步驟三 Job ID: $JOB3"

echo "🎉 全流程流水線派送完畢！Slurm 將自動按順序接續執行。"
```

---

## 📋 第四部分：與 AI 互動的標準 Prompt 範本

使用者可直接複製此提示詞貼入 Code-Server 內的 AI 助手（Claude Code / OpenCode / Zoo Code）：

```text
你是一位熟悉超級電腦 Slurm 排程器與高效能運算的專家。
我原本在終端機有一個互動式執行的腳本 `run_pipeline.sh`。
現在我希望將這套流程重構為符合國網中心創進一號（Forerunner 1 / F1）規格的 Slurm 批次作業。

【環境規範】
- 請使用我的有效計費計畫代號：#SBATCH --account=GOV114022
- 佇列分區：標準運算請用 #SBATCH --partition=ct112（若為大記憶體任務請用 cf112）
- 資源分配：單節點 4 核心（或依任務特性調整），時限預估 4 小時
- 日誌輸出：%x-%j.out 與 %x-%j.err（避開目錄相依陷阱）

【任務邏輯】
1. 請加入 set -euo pipefail 與任務啟動診斷資訊。
2. 若需連線外網，請自動加入 source set_compute_env.sh 機制。
3. 將運算軟體的平行執行緒參數綁定至 ${SLURM_CPUS_PER_TASK}。
4. 提供免扣點預檢指令：sbatch --test-only <script.slurm>。
```
