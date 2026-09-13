# HPC 實戰指南：AI Agent 技能總匯庫 (Skills Hub) 與排程專家體系

在現代超級電腦（HPC）與雲端算力環境中，人工智慧助手（如 Google Antigravity、Claude Code、Zoo Code、OpenCode）已成為研究人員不可或缺的結對編程夥伴。

然而，通用的 AI 大模型並不知道國網中心創進一號（NCHC Forerunner 1 / F1）特殊的計費錢包機制（`wallet`）、節點硬體上限（單機 112 核）、記憶體配比（`ct112` 每核 4.3GB / `cf112` 每核 8.9GB）或子路徑反向代理限制。

為了賦予 AI 助手**「超級電腦專屬的領域智慧」**，我們建立了 **HPC AI Agent 技能總匯庫（Skills Hub）**。

---

## 📌 目錄 (Table of Contents)
- [1. 什麼是 AI Agent 技能 (Skills)？為什麼 HPC 需要專屬技能？](#_1-什麼是-ai-agent-技能-skills-為什麼-hpc-需要專屬技能)
- [2. 技能庫架構與目錄速查 (Skills Catalog)](#_2-技能庫架構與目錄速查-skills-catalog)
- [3. 技能一：Slurm 排程規劃與規格防呆 (`slurm-job-advisor`)](#_3-技能一-slurm-排程規劃與規格防呆-slurm-job-advisor)
- [4. 技能二：計算節點連網與 Proxy 穿透顧問 (`compute-node-proxy`)](#_4-技能二-計算節點連網與-proxy-穿透顧問-compute-node-proxy)
- [5. 技能三：AI 自動管線重構與雙架構選型 (`ai-agent-slurm-pipeline`)](#_5-技能三-ai-自動管線重構與雙架構選型-ai-agent-slurm-pipeline)
- [6. 技能四：網頁反向代理與常駐守護 (`web-service-reverse-proxy`)](#_6-技能四-網頁反向代理與常駐守護-web-service-reverse-proxy)
- [7. 技能安裝與啟用指南 (`npx skills add` 與本地同步)](#_7-技能安裝與啟用指南-npx-skills-add-與本地同步)
- [8. 四大 HPC AI Agent Skills 實戰對話範例 (4-Round Interactive Walkthrough)](#_8-四大-hpc-ai-agent-skills-實戰對話範例-4-round-interactive-walkthrough)

---

## 1. 什麼是 AI Agent 技能 (Skills)？為什麼 HPC 需要專屬技能？

### A. 技能 (Skills) 的本質
**技能（Skill）** 是一套結構化的知識與工具集（包含 `SKILL.md` 指引、輔助腳本與範本）。當 AI Agent 偵測到使用者需要執行特定工作時，系統會自動將該技能載入 Agent 的上下文視窗中，使 AI 嚴格遵循既定流程、法規與約束。

### B. 為什麼通用 AI 容易在 HPC 上「踩大坑」？
若未載入 HPC 專屬技能，通用 AI 助手容易產生以下災難性幻覺：
1. **胡亂分配資源**：例如給出「申請 100 核心 CPU 跑一個只需 1GB 記憶體的 Python 腳本」，白白浪費 99 核心與 430 GB 記憶體配額。
2. **記憶體超出崩潰 (OOM)**：在標準薄節點（`ct112`）上申請 4 核心（僅 17.2 GB），卻執行需要 200 GB 的 SPAdes 基因組裝，導致任務被 Linux Kernel 強制終止。
3. **忽視計算節點網路隔離**：在 `.slurm` 腳本中直接寫 `pip install` 或下載模型權重，由於計算節點完全無外網，導致任務卡死超時、白扣點數。
4. **遺漏計費計畫代號**：未加入 `#SBATCH --account=`，被國網中心 Slurm 攔截拒絕排程。
5. **誤用受限佇列**：在登入節點直接提交 `sbatch -p vscode`，遭遇 `Access/permission denied` 權限錯誤。

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
│   ├── README.md                              # 說明文件與快速指令
│   ├── scripts/
│   │   ├── check_slurm_env.sh                 # 查詢 wallet 額度與可用節點
│   │   └── validate_slurm.sh                  # 靜態檢測 + sbatch --test-only 預檢
│   └── templates/                             # CPU、Fat Node、陣列作業範本
│
├── compute-node-proxy/                        # 技能 2: 計算節點實體隔離外網穿透
│   ├── SKILL.md                               # 4 步引導問答、真實內網 IP、憑證防護與精確 no_proxy
│   ├── README.md                              # 說明文件與快速指令
│   ├── scripts/                               # 完整自包含工具腳本庫 (免依賴外部目錄)
│   │   ├── check_proxy.sh                     # 診斷登入節點 Proxy 狀態與內網 IP
│   │   ├── test_compute_connection.sh         # 計算節點外網連線測試 (含 5 秒逾時保護)
│   │   ├── start.sh / stop.sh                 # 登入節點一鍵啟動/關閉 Proxy 服務
│   │   └── set_compute_env.sh                 # 計算節點一鍵載入環境變數 (含精確 no_proxy)
│   └── templates/
│       └── job_with_proxy.slurm               # 具備連線預檢的 Slurm 排程範本
│
├── ai-agent-slurm-pipeline/                   # 技能 3: 互動管線自動轉為批次排程
│   ├── SKILL.md                               # 離線 (Case A) vs Proxy (Case B) 決策樹
│   ├── README.md                              # 說明文件
│   ├── prompts/                               # 專屬提示詞範本
│   └── templates/                             # 離線與 Proxy 雙模式 Slurm 管線範本
│
└── web-service-reverse-proxy/                 # 技能 4: 網頁服務反向代理與背景常駐
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

## 4. 技能二：計算節點連網與 Proxy 穿透顧問 (`compute-node-proxy`)

> **主要職責**：徹底解決「計算節點處於實體隔離內網，完全無外網連線能力」的超級電腦痛點。當使用者需要下載模型權重、安裝套件、串接即時監控（Weights & Biases）或呼叫外部 API 時，主動引導連網決策並配置安全代理。

### A. 五步結構化引導問答 (Interactive Q&A)
1. **連網型態診斷（預載離線 vs 即時連網）**：
   - 詢問使用者：「請問資料或權重能否在登入節點預先下載好（推薦），還是作業執行時必須即時動態連網？」
   - 若為靜態權重（如 20GB LLM 權重或固定資料庫），引導先在登入節點下載至 `/work` 共享目錄，計算節點純離線執行，避免幾十個節點同時下載擠爆頻寬。
2. **登入節點 Proxy 狀態探測**：
   - AI 自動調用 `check_proxy.sh` 檢查登入節點上的 Proxy 服務（`tmux session: http-proxy` 監聽 Port 8888）是否正在運行。
   - 若未啟動，主動提供一鍵啟動指令 `bash ~/hpc-tutorial/07-compute-node-proxy/scripts/start.sh`。
3. **安全憑證保護與精確 `no_proxy` 配置**：
   - 杜絕在指令或腳本中暴露明文密碼，強制引導使用 `~/.proxy_auth`（權限必須為 `600`）在記憶體中動態載入。
   - 內網直連排除設為 `10.0.0.0/8,172.16.0.0/12`（已涵蓋叢集節點與 MPI 通訊）。**切勿隨意加入 `*.nchc.org.tw` 萬用字元**，否則連線至 `www.nchc.org.tw` 官網等公開網站時會因計算節點無外網直連而逾時失敗。
4. **外網連線防呆預檢（Fail-Fast 機制）**：
   - 在生成的 Slurm 腳本頂部加入 5 秒外網連線快速預檢，若網路未通立即報錯退出，避免排程在無網路狀態下空轉數小時浪費計畫點數（SU）：
     ```bash
     if ! curl -s -I --connect-timeout 5 https://huggingface.co > /dev/null; then
         echo "❌ 嚴重錯誤：計算節點無法透過 Proxy 連線外網，終止作業以避免浪費點數！"
         exit 1
     fi
     ```
5. **作業完成後的收尾提醒 (Teardown & Cleanup)**：
   - 連網排程作業完成後，AI 主動詢問使用者是否關閉登入節點的 Proxy 服務，釋放 Port 8888 資源並降低憑證暴露風險（`bash stop.sh`）。

### B. 內建實用工具
```bash
# 1. 診斷登入節點 Proxy 運行狀態、IP 與憑證
bash ~/hpc-tutorial/09-skills-hub/compute-node-proxy/scripts/check_proxy.sh

# 2. 計算節點外網連線快速測試 (預設測試 https://huggingface.co)
bash ~/hpc-tutorial/09-skills-hub/compute-node-proxy/scripts/test_compute_connection.sh

# 3. 啟動登入節點 Proxy 背景常駐 (tmux session)
bash ~/hpc-tutorial/07-compute-node-proxy/scripts/start.sh

# 4. 關閉登入節點 Proxy 背景常駐 (連網作業完成後建議主動關閉釋放資源)
bash ~/hpc-tutorial/07-compute-node-proxy/scripts/stop.sh
```

---

## 5. 技能三：AI 自動管線重構與雙架構選型 (`ai-agent-slurm-pipeline`)

> **主要職責**：將使用者在 Code-Server 終端機除錯好的互動式指令，全自動改寫為健壯的 Slurm 批次腳本。

### A. 兩大運算架構決策
1. **架構 A：事前下載 / 純離線運算模式 (Pre-Staged Offline)**
   - 資料預先存於 `/work1` 高速區，計算節點純離線執行。最穩定、不依賴登入節點 Proxy。
2. **架構 B：動態掛載 HTTP Proxy 即時下載模式 (Dynamic Proxy)**
   - 透過第 07 章建立的 Tinyproxy/proxy.py 隧道，在計算節點載入 `set_compute_env.sh`，讓計算節點在運算中即時拉取外部模型或 API。

### B. 自動化相依管線串接 (`--dependency=afterok:`)
引導使用者將「資料前處理 ➔ 核心計算 ➔ 報告整合」透過指令串成無人值守流水線：
```bash
JOB1=$(sbatch --parsable step1_prep.slurm)
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 step2_calc.slurm)
JOB3=$(sbatch --parsable --dependency=afterok:$JOB2 step3_report.slurm)
```

---

## 6. 技能四：網頁反向代理與常駐守護 (`web-service-reverse-proxy`)

> **主要職責**：解決在超級電腦上啟動 Web UI、API 與互動視覺化報表的所有網路與後台進程痛點。

* **動態連接埠尋找**：透過 Python 一鍵動態取得未佔用 Port，根絕 `EADDRINUSE`。
* **OOD 子路徑適應**：提供 Vite / Next.js / Streamlit / Gradio 的 `base` 相對路徑設定，防止 CSS/JS 破圖。
* **安全性放行**：設定 `allowedHosts: true`，防止反向代理標頭被本機伺服器拒絕。
* **背景守護**：採用 `tmux` 或 `setsid` 隔離終端，避免 SSH 斷線中斷與背景輸入死鎖（SIGTTIN）。

---

## 7. 技能安裝與啟用指南 (`npx skills add` 與本地同步)

本技能庫完全相容目前主流的 **Open Agent Skills 生態體系（skills.sh）**，支援以跨平台指令一鍵安裝，亦支援主機本地腳本同步。

### 方法一：使用現代標準 `npx skills add` 一鍵安裝 🌟 (跨主機/跨工具最推薦)

只要環境具備 Node.js / npx（創進一號已預載），任何人皆可透過官方標準的 `skills` 工具，將本倉庫的技能直接安裝至本機或全域 Agent 設定中：

#### 1. 列出倉庫內所有可用技能：
```bash
npx -y skills add gemini960114/F1-docs -l
```
*系統將自動解析出 `slurm-job-advisor`、`compute-node-proxy`、`ai-agent-slurm-pipeline` 與 `web-service-reverse-proxy` 四大技能。*

#### 2. 一鍵安裝全數技能（全域模式，支援所有 Agent）：
```bash
npx -y skills add gemini960114/F1-docs -g -y
```

#### 3. 針對特定 Agent 或單一技能安裝：
```bash
# 僅安裝 compute-node-proxy 技能：
npx -y skills add gemini960114/F1-docs --skill compute-node-proxy -g -y

# 指定安裝至特定 AI 工具 (如 claude-code, antigravity, cursor)：
npx -y skills add gemini960114/F1-docs -a claude-code antigravity cursor -g -y
```

---

### 方法二：創進一號叢集本地一鍵同步腳本

若您已在創進一號登入節點或內部網路環境中，亦可直接使用教程隨附的同步腳本：

```bash
bash ~/hpc-tutorial/09-skills-hub/sync_skills.sh
```

執行後，所有技能將自動同步至 `~/.agents/skills/`，Google Antigravity、Claude Code、OpenCode 或 Zoo Code 啟動時即會自動載入！

---

## 8. 四大 HPC AI Agent Skills 實戰對話範例 (4-Round Interactive Walkthrough)

本節示範專案內 4 個 Skill 的實際使用方式。每一輪皆以**「使用者提問 ➔ AI 多輪追問確認 ➔ 產出與驗證 ➔ 派送/執行」**的完整生命週期呈現。AI 不會在資訊不足時盲目猜測，而是主動發起結構化引導，在確認合規後才動作。

| 輪次 | 觸發 Skill | 實戰情境 | 核心價值 |
| :--- | :--- | :--- | :--- |
| **第一輪** | `slurm-job-advisor` | 派送一般運算作業，資源規劃與免扣點預檢 | 自動查驗 `wallet` 額度、防呆換算、`sbatch --test-only` 零扣點預檢 |
| **第二輪** | `compute-node-proxy` | 計算節點需要連外網下載資料 | 自動探測/啟動 Proxy、修正 `no_proxy` 官網超時、作業完成收尾提醒 |
| **第三輪** | `ai-agent-slurm-pipeline` | 把互動式多步驟腳本轉換為鏈式批次管線 | 純離線 vs 動態 Proxy 架構選型、`--dependency=afterok:` 自動接龍 |
| **第四輪** | `web-service-reverse-proxy` | 在 OOD 子路徑背景啟動 Web 服務 | 動態尋找空閒 Port、適應 `/rnode/` 子路徑、`tmux` 背景守護免死鎖 |

---

### 第一輪：`slurm-job-advisor` — 派送一般運算作業與免扣點預檢

#### 📖 情境設定
使用者想在計算節點跑一個簡單的測試作業，但未指定計畫代號與佇列。

> 🧑‍💻 **使用者提問**：  
> *「我要派送 slurm job，1 core cpu 任務 sleep 100」*

🤖 **AI 助手反應（主動載入 `slurm-job-advisor`，先探測即時環境）**：
```bash
bash <此 skill 的 scripts 目錄>/check_slurm_env.sh
```
*系統即時回報：帳號 `GOV114022` / `GOV108018` / `GOV115071` 等計畫餘額，以及 `development`、`ct112`、`cf112`、`hm112` 目前的閒置節點數。*

💬 **AI 追問（多輪問答第 1 次）**：
> 「這是一個 `sleep 100` 的輕量測試任務，推薦使用 **`development` 佇列**（1 核心、8 小時時限內享有最高優先權，幾乎秒排秒跑）。目前偵測到您有以下可用計畫代號，請問要從哪個扣點？」  
> 1. `GOV115071`（餘額充裕）  
> 2. `GOV114022`  
> 3. `GOV108018`

🧑‍💻 **使用者選擇**：`GOV115071`

📝 **AI 自動產出腳本**（`sleep100.slurm`，含 `#SBATCH -A GOV115071`、`#SBATCH -p development`、`set -euo pipefail` 與診斷標頭），接著主動執行免扣點測試：
```bash
bash <此 skill 的 scripts 目錄>/validate_slurm.sh sleep100.slurm
# ✅ 靜態檢查：Account、Partition 與資源比例合規
# ✅ sbatch --test-only 免扣點預檢通過，預計立即啟動！
```

💬 **AI 回報**：
> 「預檢已順利通過！請問是否現在為您正式提交至排程系統？」

🧑‍💻 **使用者確認**：*「派送」*

🚀 **AI 正式派送**：
```bash
sbatch sleep100.slurm
# Submitted batch job 1073943
```
*主動提示使用者監控指令：`squeue -j 1073943`，並提醒作業結束後可用 `seff 1073943` 檢視 CPU 與記憶體真實利用率。*

> 💡 **核心教學重點**：AI 絕不在缺少 `--account` 時隨機編造，而是列出即時 `wallet` 額度供使用者確認；資源規格亦會自動識別為「測試任務」而推薦最高優先權的 `development`，避免新手的除錯作業在常規佇列大排長龍。

---

### 第二輪：`compute-node-proxy` — 計算節點連外網與故障排查實戰

#### 📖 情境設定
使用者要在 Slurm 作業中建立資料夾並下載外部網頁，但計算節點處於實體隔離內網。

> 🧑‍💻 **使用者提問**：  
> *「我要重新派送這個工作：建立一個 ~/website 資料夾，然後下載 www.nchc.org.tw 這一頁面的資料」*

🤖 **AI 助手反應（偵測到「下載外部網頁」關鍵字，主動觸發 `compute-node-proxy`）**：

**1. 探測登入節點 Proxy 狀態**：
```bash
bash <此 skill 的 scripts 目錄>/check_proxy.sh
# 🛑 Proxy 服務狀態: 🔴 尚未啟動
```

💬 **AI 主動告知**：
> 「計算節點無外網連線能力。偵測到登入節點的 Proxy 服務尚未啟動，我將為您啟動背景代理隧道。」

**2. 啟動背景代理**：
```bash
bash <此 skill 的 scripts 目錄>/start.sh
# 🎉 HTTP Proxy 成功於背景 (tmux) 啟動！
# 認證憑證已安全寫入 ~/.proxy_auth (權限 600)
```

**3. 產出排程腳本（`download_nchc.slurm`）**：
- 動態載入 `source <此 skill 的 scripts 目錄>/set_compute_env.sh`（不將密碼明文暴露在指令或腳本中）。
- 加入 Fail-Fast 5 秒連線預檢。
- 執行 `mkdir -p ~/website && wget -nv -P ~/website https://www.nchc.org.tw`。

**4. 第一次預檢遭遇失敗（多輪問答的關鍵：精準故障根因排查）**：
```text
❌ 錯誤：計算節點無法連線至 https://www.nchc.org.tw (逾時 5 秒)
```
🔍 **AI 診斷根因**：
> 「排查發現：預設 `no_proxy` 包含了萬用字元 `*.nchc.org.tw`，導致這個對外公開網站被誤判為『內網直連』，跳過了 Proxy 隧道；但計算節點本身無外網，因而連線逾時。」

🔧 **AI 自動修正腳本**（從 `no_proxy` 移除該萬用字元，僅保留 `10.0.0.0/8,172.16.0.0/12` 內網網段），並重新派送：
```bash
sbatch download_nchc.slurm
# Submitted batch job 1073964 ➔ COMPLETED (狀態: 成功)
# ~/website/index.html 下載完成！
```

**5. 作業完成後的生命週期收尾（步驟 5）**：
💬 **AI 主動詢問**：
> 「此次連網作業已順利完成，登入節點的 Proxy 服務目前仍在背景常駐運作（Port 8888）。是否需要現在關閉以釋放資源、降低資安暴露面？」

🧑‍💻 **使用者確認**：*「關閉」*

🧹 **AI 執行清理**：
```bash
bash <此 skill 的 scripts 目錄>/stop.sh
# ✅ HTTP Proxy 服務已安全關閉！
```

> 💡 **核心教學重點**：AI 先探測再啟動，絕不在腳本留明文密碼；遇到外網連線逾時能準確定位出 `no_proxy` 萬用字元問題，且任務完成後主動提醒關閉 Proxy，避免長期佔用共用伺服器資源。

---

### 第三輪：`ai-agent-slurm-pipeline` — 互動腳本重構為鏈式批次管線

#### 📖 情境設定
使用者手上有一套在終端機逐步手動跑的分析流程，希望改寫為全自動接力的 Slurm 批次流水線。

> 🧑‍💻 **使用者提問**：  
> *「我有一支互動用的 shell 腳本，會依序做：1) 資料前處理與品質過濾 2) 主力序列比對 3) 產生分析報告，且中間會下載一份外部參考資料庫。想幫我改成 Slurm 批次管線。」*

💬 **AI 追問（多輪問答第 1 次：架構選型決策）**：
> 「請問這三個步驟中，外部參考資料庫**能否在登入節點預先下載好**（推薦架構 A：純離線模式），還是必須在計算節點運算當下動態連網下載（架構 B：動態 Proxy 模式）？」

🧑‍💻 **使用者回應**：*「參考資料庫可以先在登入節點下載好，後面比對跟報告都是純離線運算。」*

💬 **AI 追問（多輪問答第 2 次：資源與相依策略確認）**：
> 「確認採用【架構 A：事前下載 ＋ 計算節點純離線】。請問三個階段各自預估的核心數與時限？若任一階段失敗，下游作業是否整條中斷？」

🧑‍💻 **使用者回應**：*「前處理 4 核心 30 分鐘、比對 16 核心 4 小時、報告 2 核心 20 分鐘；任一步失敗就整條中斷即可。」*

📝 **AI 產出三階段腳本並自動串接鏈式依賴**：
```bash
# 階段 1：資料前處理 (4 核心, 30 分鐘)
JOB1=$(sbatch --parsable 01_preprocess.slurm)

# 階段 2：主力序列比對 (16 核心, 4 小時，依賴 JOB1 成功執行)
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 02_alignment.slurm)

# 階段 3：產生分析報告 (2 核心, 20 分鐘，依賴 JOB2 成功執行)
JOB3=$(sbatch --parsable --dependency=afterok:$JOB2 03_report.slurm)
```
每支腳本頂部皆包含 `set -euo pipefail`，確保上游只要遇到任何錯誤碼，下游 `afterok` 作業便會被排程器直接取消（DependencyNeverSatisfied），絕不浪費點數產出錯誤資料。

🛡️ **AI 派送前主動預檢**：對三支腳本各自執行 `sbatch --test-only`，確認語法、分區與計畫額度皆完全合規後才正式接龍提交！

> 💡 **核心教學重點**：AI 會先釐清「連網 vs 離線」架構決策（避免過度依賴 Proxy），再詢問資源規模與容錯策略，最後以 `--dependency=afterok:` 自動串接，徹底杜絕手動替換 Job ID 容易改錯的低級失誤。

---

### 第四輪：`web-service-reverse-proxy` — 在 OOD 子路徑背景啟動 Web 服務

#### 📖 情境設定
使用者想在 Open OnDemand (OOD) 的 code-server 瀏覽器環境中，啟動一個 Streamlit 數據儀表板供團隊即時檢視。

> 🧑‍💻 **使用者提問**：  
> *「我想在這個 code-server 環境跑一個 Streamlit app，讓我可以用瀏覽器打開看儀表板。」*

💬 **AI 追問（多輪問答第 1 次：確認執行環境與埠號分配）**：
> 「目前您是透過 Open OnDemand 的子路徑反向代理存取，Streamlit 預設埠號（8501）很容易與他人衝突。請問要指定特定埠號，還是由我為您**動態探測一個保證未佔用的空閒埠號**？」

🧑‍💻 **使用者回應**：*「你幫我找一個空的就好。」*

🔍 **AI 動態偵測可用空埠**：
```bash
python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1])"
# → 取得可用埠號: 41235
```

💬 **AI 追問（多輪問答第 2 次：子路徑前綴與背景常駐方式）**：
> 「在 OOD 反向代理下，Streamlit 必須設定 `--server.baseUrlPath` 對齊路徑前綴，且必須透過 `tmux` 背景守護以防止終端輸入死鎖（SIGTTIN）。請提供您當前瀏覽器網址列中的代理路徑前綴（例如 `/rnode/<主機名>/<埠號>/`）？」

🧑‍💻 **使用者提供前綴**：`/rnode/ilgn01/41235/`

🚀 **AI 產出啟動指令並在背景常駐執行**：
```bash
tmux new-session -d -s streamlit_dash \
  "streamlit run dashboard.py \
     --server.port=41235 \
     --server.baseUrlPath=/rnode/ilgn01/41235/ \
     --server.headless=true \
     --server.enableCORS=false"
```

🧪 **AI 主動驗證服務監聽狀態**：
```bash
curl -sI http://localhost:41235/rnode/ilgn01/41235/ | head -n 1
# HTTP/1.1 200 OK  ➔ 服務正常監聽中！
```

💬 **AI 回報**：
> 「Streamlit 儀表板已在背景成功啟動！  
> 🔗 **瀏覽器存取網址**：`https://<OOD網址>/rnode/ilgn01/41235/`  
> 💡 欲停止服務釋放連接埠，請執行：`tmux kill-session -t streamlit_dash`」

> 💡 **核心教學重點**：AI 會主動避開固定埠號衝突，自動設定關鍵的 `baseUrlPath` 防止前端靜態資源破圖（404），並採用 `tmux` 避免終端關閉導致服務斷線，最後主動發送 HTTP 請求驗證服務存活。

---

### 📌 四輪共通核心設計哲學 (Core Design Patterns)

回顧上述 4 個 Skill 的實戰歷程，AI Agent 始終遵循以下四大黃金法則：

1. **絕不在資訊不全時盲目猜測**：計畫帳號、分區配比、連網型態、代理前綴等關鍵參數，一律透過多輪問答引導釐清。
2. **執行前必定落實預檢（Fail-Fast）**：`sbatch --test-only` 免扣點驗證、5 秒連線探測、Port 存活檢測，寧可提前攔截也不讓錯誤作業消耗寶貴點數。
3. **遇到失敗先診斷根因，而非暴力重試**：如同第二輪中準確抓出 `no_proxy` 萬用字元問題，排除真正問題後才再次派送。
4. **主動提醒資源收尾（Teardown & Cleanup）**：排程結束後提醒關閉 Proxy 隧道、Web 服務提供明確關閉指令，杜絕佔用共用伺服器資源。


