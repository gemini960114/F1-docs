# HPC 實戰指南：AI Agent 技能總匯庫 (Skills Hub) 與排程專家體系

在現代超級電腦（HPC）與雲端算力環境中，人工智慧助手（如 Google Antigravity、Claude Code、Zoo Code、OpenCode）已成為研究人員不可或缺的結對編程夥伴。

然而，通用的 AI 大模型並不知道國網中心（NCHC Taiwania 1 / f1）特殊的計費錢包機制（`wallet`）、節點硬體上限（單機 112 核）、記憶體配比（`ct112` 每核 4.3GB / `cf112` 每核 8.9GB）或子路徑反向代理限制。

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
- [8. 實戰演練：從自然語言提問到合規派送](#_8-實戰演練-從自然語言提問到合規派送)

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
│   ├── scripts/
│   │   ├── check_slurm_env.sh                 # 查詢 wallet 額度與可用節點
│   │   └── validate_slurm.sh                  # 靜態檢測 + sbatch --test-only 預檢
│   └── templates/                             # CPU、Fat Node、陣列作業範本
│
├── compute-node-proxy/                        # 技能 2: 計算節點實體隔離外網穿透
│   ├── SKILL.md                               # 4 步引導問答、真實內網 IP 與安全憑證防呆
│   ├── scripts/
│   │   ├── check_proxy.sh                     # 診斷登入節點 Proxy 狀態與內網 IP
│   │   └── test_compute_connection.sh         # 計算節點外網連線測試 (含 5 秒逾時保護)
│   └── templates/
│       └── job_with_proxy.slurm               # 具備連線預檢的 Slurm 排程範本
│
├── ai-agent-slurm-pipeline/                   # 技能 3: 互動管線自動轉為批次排程
│   ├── SKILL.md                               # 離線 (Case A) vs Proxy (Case B) 決策樹
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

## 8. 實戰演練：從自然語言提問到合規派送

### 範例一：資源規格防呆與換算
> **使用者提問**：  
> *「我想要在創進一號跑一個 Python 批次資料分析，但我不知道怎麼寫 Slurm 腳本，大概需要 50GB 記憶體，幫我規劃一下。」*

**AI 觸發技能後的專業回應流程**：
1. **調用 `check_slurm_env.sh`**：取得可用的 `wallet` 計畫代號（如 `GOV114022`）。
2. **規格換算與防呆**：
   - 使用者需要 50GB 記憶體。
   - 若在 `ct112`（每核 4.3GB）上，需要配置 `50 / 4.3 ≈ 12` 核心（獲得約 51.6 GB RAM）。
   - 若在 `cf112`（每核 8.9GB）上，只需配置 `50 / 8.9 ≈ 6` 核心（獲得約 53.4 GB RAM）。
   - 向使用者建議：「若您的程式支援多執行緒平行，推薦 `ct112` 12 核心；若程式多為單核計算，推薦使用 `cf112` 6 核心以減少 SU 核心時浪費。」
3. **自動產生標頭規範完整、含 `set -euo pipefail` 的 `.slurm` 腳本**。
4. **主動調用 `validate_slurm.sh`** 進行 `sbatch --test-only` 免扣點預檢，並回傳預計啟動時間！

### 範例二：計算節點連網與 Proxy 防呆
> **使用者提問**：  
> *「我想寫個 Slurm 腳本在計算節點跑 PyTorch 模型微調，程式中需要自動從 Hugging Face 下載權重，該怎麼寫？」*

**AI 觸發技能後的專業回應流程**：
1. **連網型態診斷與架構建議**：
   - 詢問模型大小。若權重達數十 GB，優先建議先在登入節點執行 `huggingface-cli download` 儲存至 `/work`。
   - 若確認需要在計算節點直接連線下載，啟動 Proxy 流程。
2. **調用 `check_proxy.sh`** 探測登入節點 Proxy 狀態。若未啟動，指導使用者執行 `bash ~/hpc-tutorial/07-compute-node-proxy/scripts/start.sh`。
3. **安全注入 `source set_compute_env.sh`**（走 InfiniBand 內網 `10.200.160.1:8888`，絕不暴露明文密碼）。
4. **自動在腳本開頭加入 5 秒連線預檢**，若外網中斷則立即中止排程，確保不白扣計畫 SU 點數！

