# HPC 實戰指南：AI Agent 技能總匯庫 (Skills Hub) 與排程專家體系

在現代超級電腦（HPC）與雲端算力環境中，人工智慧助手（如 Google Antigravity、Claude Code、Zoo Code、OpenCode）已成為研究人員不可或缺的結對編程夥伴。

然而，通用的 AI 大模型並不知道國網中心（NCHC Taiwania 1 / f1）特殊的計費錢包機制（`wallet`）、節點硬體上限（單機 112 核）、記憶體配比（`ct112` 每核 4.3GB / `cf112` 每核 8.9GB）或子路徑反向代理限制。

為了賦予 AI 助手**「超級電腦專屬的領域智慧」**，我們建立了 **HPC AI Agent 技能總匯庫（Skills Hub）**。

---

## 📌 目錄 (Table of Contents)
- [1. 什麼是 AI Agent 技能 (Skills)？為什麼 HPC 需要專屬技能？](#_1-什麼是-ai-agent-技能-skills-為什麼-hpc-需要專屬技能)
- [2. 技能庫架構與目錄速查 (Skills Catalog)](#_2-技能庫架構與目錄速查-skills-catalog)
- [3. 技能一：Slurm 排程規劃與規格防呆 (`slurm-job-advisor`)](#_3-技能一-slurm-排程規劃與規格防呆-slurm-job-advisor)
- [4. 技能二：AI 自動管線重構與雙架構選型 (`ai-agent-slurm-pipeline`)](#_4-技能二-ai-自動管線重構與雙架構選型-ai-agent-slurm-pipeline)
- [5. 技能三：網頁反向代理與常駐守護 (`web-service-reverse-proxy`)](#_5-技能三-網頁反向代理與常駐守護-web-service-reverse-proxy)
- [6. 一鍵同步安裝與 Agent 啟用指南](#_6-一鍵同步安裝與-agent-啟用指南)
- [7. 實戰演練：從自然語言提問到合規派送](#_7-實戰演練-從自然語言提問到合規派送)

---

## 1. 什麼是 AI Agent 技能 (Skills)？為什麼 HPC 需要專屬技能？

### A. 技能 (Skills) 的本質
**技能（Skill）** 是一套結構化的知識與工具集（包含 `SKILL.md` 指引、輔助腳本與範本）。當 AI Agent 偵測到使用者需要執行特定工作時，系統會自動將該技能載入 Agent 的上下文視窗中，使 AI 嚴格遵循既定流程、法規與約束。

### B. 為什麼通用 AI 容易在 HPC 上「踩大坑」？
若未載入 HPC 專屬技能，通用 AI 助手容易產生以下災難性幻覺：
1. **胡亂分配資源**：例如給出「申請 100 核心 CPU 跑一個只需 1GB 記憶體的 Python 腳本」，白白浪費 99 核心與 430 GB 記憶體配額。
2. **記憶體超出崩潰 (OOM)**：在標準薄節點（`ct112`）上申請 4 核心（僅 17.2 GB），卻執行需要 200 GB 的 SPAdes 基因組裝，導致任務被 Linux Kernel 強制終止。
3. **遺漏計費計畫代號**：未加入 `#SBATCH --account=`，被國網中心 Slurm 攔截拒絕排程。
4. **誤用受限佇列**：在登入節點直接提交 `sbatch -p vscode`，遭遇 `Access/permission denied` 權限錯誤。

**HPC 專屬技能庫正是為杜絕上述問題而生的「守門員與加速器」！**

---

## 2. 技能庫架構與目錄速查 (Skills Catalog)

所有技能集中存放於教學資源目錄 `~/hpc-tutorial/09-skills-hub/`（亦可透過捷徑 `~/hpc-tutorial/skills-hub` 存取）：

```text
~/hpc-tutorial/09-skills-hub/
├── README.md                                  # 技能庫總覽說明
├── sync_skills.sh                             # 一鍵同步至 ~/.agents/skills/ 工具
│
├── slurm-job-advisor/                         # 技能 1: 排程規劃、錢包查詢與規格防呆
│   ├── SKILL.md                               # 核心規範、4 步問答模板與硬體矩陣
│   ├── scripts/
│   │   ├── check_slurm_env.sh                 # 查詢 wallet 額度與可用節點
│   │   └── validate_slurm.sh                  # 靜態檢測 + sbatch --test-only 預檢
│   └── templates/                             # CPU、Fat Node、陣列作業範本
│
├── ai-agent-slurm-pipeline/                   # 技能 2: 互動管線自動轉為批次排程
│   ├── SKILL.md                               # 離線 (Case A) vs Proxy (Case B) 決策樹
│   ├── prompts/                               # 專屬提示詞範本
│   └── templates/                             # 離線與 Proxy 雙模式 Slurm 管線範本
│
└── web-service-reverse-proxy/                 # 技能 3: 網頁服務反向代理與背景常駐
    ├── SKILL.md                               # OOD /rnode/ 網址規範、動態 Port 與 tmux 守護
    └── README.md                              # 前端與 Python 網頁框架配置指引
```

---

## 3. 技能一：Slurm 排程規劃與規格防呆 (`slurm-job-advisor`)

> **主要職責**：動態對接國網 `wallet`，引導需求問答，防範不合常理的資源申請，並自動產出合規腳本。

### A. 四步結構化引導問答 (Interactive Interview)
當使用者需求不明確時，Agent 會發起精準的 4 步提問：
1. **💳 計畫代號確認**：自動調用 `wallet` 列出擁有正數點數的計畫代號供使用者選擇。
2. **🔬 軟體與任務特徵**：了解是常規數據分析、生醫組裝、多樣本平行還是 MPI 分散運算。
3. **⚡ 資源與記憶體合理化換算**：
   - 輕量級（< 16 GB）➔ `ct112`（4 核心，附帶 17.2 GB RAM）
   - 中量級（16 ~ 64 GB）➔ `ct112`（8 ~ 16 核心，附帶 34 ~ 68 GB RAM）
   - 重度大記憶體（> 64 GB ~ 1 TB）➔ 大記憶體 Fat Node `cf112`（每核心配發 8.9 GB RAM）
4. **⏱️ 執行時限與通知**：評估合理的 Walltime（預估 1.5~2 倍作為緩衝）並設定 Email 通報。

### B. 內建實用工具
```bash
# 1. 查詢 wallet 餘額與登入節點可用資源
bash ~/hpc-tutorial/09-skills-hub/slurm-job-advisor/scripts/check_slurm_env.sh

# 2. 靜態分析 + 排程器免扣點預檢
bash ~/hpc-tutorial/09-skills-hub/slurm-job-advisor/scripts/validate_slurm.sh my_job.slurm
```

---

## 4. 技能二：AI 自動管線重構與雙架構選型 (`ai-agent-slurm-pipeline`)

> **主要職責**：將使用者在 Code-Server 終端機除錯好的互動式指令，全自動改寫為健壯的 Slurm 批次腳本。

### A. 兩大運算架構決策
1. **架構 A：事前下載 / 純離線運算模式 (Pre-Staged Offline)**
   - 資料預先存於 `/work1` 高速區，計算節點純離線執行。最穩定、不依賴登入節點 Proxy。
2. **架構 B：動態掛載 HTTP Proxy 即時下載模式 (Dynamic Proxy)**
   - 透過第 07 章建立的 Tinyproxy 隧道，在計算節點載入 `set_compute_env.sh`，讓計算節點在運算中即時拉取外部模型或 API。

### B. 自動化相依管線串接 (`--dependency=afterok:`)
引導使用者將「資料前處理 ➔ 核心計算 ➔ 報告整合」透過指令串成無人值守流水線：
```bash
JOB1=$(sbatch --parsable step1_prep.slurm)
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 step2_calc.slurm)
JOB3=$(sbatch --parsable --dependency=afterok:$JOB2 step3_report.slurm)
```

---

## 5. 技能三：網頁反向代理與常駐守護 (`web-service-reverse-proxy`)

> **主要職責**：解決在超級電腦上啟動 Web UI、API 與互動視覺化報表的所有網路與後台進程痛點。

* **動態連接埠尋找**：透過 Python 一鍵動態取得未佔用 Port，根絕 `EADDRINUSE`。
* **OOD 子路徑適應**：提供 Vite / Next.js / Streamlit / Gradio 的 `base` 相對路徑設定，防止 CSS/JS 破圖。
* **安全性放行**：設定 `allowedHosts: true`，防止反向代理標頭被本機伺服器拒絕。
* **背景守護**：採用 `tmux` 或 `setsid` 隔離終端，避免 SSH 斷線中斷與背景輸入死鎖（SIGTTIN）。

---

## 6. 一鍵同步安裝與 Agent 啟用指南

系統自動辨識放置於 `~/.agents/skills/` 目錄下的技能。

### 一鍵同步指令：
```bash
bash ~/hpc-tutorial/09-skills-hub/sync_skills.sh
```

執行後，`slurm-job-advisor`、`ai-agent-slurm-pipeline` 與 `web-service-reverse-proxy` 即刻生效。當您在 Code-Server、Antigravity CLI 或 Claude Code 中提出相關任務時，AI 將無縫啟動專屬技能！

---

## 7. 實戰演練：從自然語言提問到合規派送

### 情境範例：
> **使用者提問**：  
> *「我想要在創進一號跑一個 Python 批次資料分析，但我不知道怎麼寫 Slurm 腳本，大概需要 50GB 記憶體，幫我規劃一下。」*

### AI 觸發技能後的專業回應流程：
1. **調用 `check_slurm_env.sh`**：取得可用的 `wallet` 計畫代號（如 `GOV114022`）。
2. **規格換算與防呆**：
   - 使用者需要 50GB 記憶體。
   - 若在 `ct112`（每核 4.3GB）上，需要配置 `50 / 4.3 ≈ 12` 核心（獲得約 51.6 GB RAM）。
   - 若在 `cf112`（每核 8.9GB）上，只需配置 `50 / 8.9 ≈ 6` 核心（獲得約 53.4 GB RAM）。
   - 向使用者建議：「若您的程式支援多執行緒平行，推薦 `ct112` 12 核心；若程式多為單核計算，推薦使用 `cf112` 6 核心以減少 SU 核心時浪費。」
3. **自動產生標頭規範完整、含 `set -euo pipefail` 的 `.slurm` 腳本**。
4. **主動調用 `validate_slurm.sh`** 進行 `sbatch --test-only` 免扣點預檢，並回傳預計啟動時間！
