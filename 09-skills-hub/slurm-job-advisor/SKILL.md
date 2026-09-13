---
name: slurm-job-advisor
description: >-
  Comprehensive guide, interactive questionnaire system, and resource sizing engine for generating
  production-ready Slurm batch scripts on NCHC Taiwania 1 (f1) and HPC clusters.
  Inspects real-time `wallet` project balances and `sinfo` partition capabilities, conducts a guided
  interactive interview to elicit missing user requirements, prevents absurd resource allocations
  (such as 100 CPU cores with 1GB RAM or memory exceeding partition limits), maps scientific software
  workloads to realistic hardware profiles, and provides automated script generation and pre-flight
  validation via `sbatch --test-only`.
---

# Slurm Job Advisor & Resource Sizing Expert (國網創進一號專用)

本技能（Skill）專門指導 AI Assistant 在超級電腦（HPC，特別是國網中心創進一號 Taiwania 1 / f1）環境中，引導使用者完成合理、合規、絕不踩坑的 Slurm 排程腳本規劃與生成。

---

## 📌 核心觸發情境 (When to Activate)

當使用者出現以下任何一種意圖時觸發本技能：
1. **明確提出需求**：指定了計畫代號、CPU 核心數、運行時間，要求產生 `.slurm` 排程腳本。
2. **提出計算軟體但不知如何配置**：例如「我要跑 GATK / SPAdes / Python 數據分析，幫我寫 Slurm 腳本」，需要 AI 依據軟體特性推薦適當的 CPU 與記憶體。
3. **需求模糊或未提供說明**：僅表示「幫我寫個 Slurm 腳本」或「我想派送作業到計算節點」，缺少帳號、核心或時間等關鍵資訊。

---

> 💡 **可攜性與腳本路徑說明**：本 Skill 所有輔助腳本皆位於此 Skill 自身安裝目錄的 `scripts/` 資料夾內（載入本 Skill 時系統會提供實際安裝路徑），完全獨立自足。AI 執行或引導執行輔助腳本時，務必以當次實際安裝路徑調用（以下範例以 `<此 skill 的 scripts 目錄>/xxx.sh` 表示），而非沿用固定字串。

## 🏛️ 第一部分：創進一號 (f1) 硬體真相與資源約束矩陣

在給出任何建議前，AI **必須嚴格基於叢集真實硬體與排程架構**，杜絕幻覺與不合理配置：

### 1. 節點與記憶體架構
* **單一計算節點物理核心上限**：x86 架構節點為 **112 實體核心**（Intel Xeon Platinum 8280, 2 Sockets × 28 Cores × 2 Threads）。
* **Slurm 排程核心與記憶體綁定**：叢集採用 `SelectTypeParameters=CR_CORE_MEMORY`，**記憶體為消耗性資源（Consumable Resource）**。
* **分區記憶體配額標準**：
  * **薄節點 (`ct112`)**：**4,308 MB / 核心**（約 4.2 GB/核），單節點總記憶體約 482 GB。
  * **大記憶體節點 (`cf112`)**：**8,916 MB / 核心**（約 8.7 GB/核），單節點總記憶體約 998 GB (~1 TB)。
  * **巨型記憶體節點 (`hm112`)**：**18,130 MB / 核心**（約 17.7 GB/核），單節點總記憶體約 2,030 GB (~2 TB)。
  * **快速除錯佇列 (`development`)**：4,308 MB / 核心，時限上限 **8 小時**，優先權最高 (`PriorityJobFactor=1000`)，每用戶同時間限 1 個 Running 作業。

### 2. 登入節點 (`ilgn01/02`) 派送權限清單 (`AllocNodes`)
* ✅ **可直接派送**：`development`、`ct112`、`ct448~ct8k`、`cf112`、`cf448~cf4k`、`hm112`、`hm448`。
* ❌ **登入節點嚴禁直接派送（排程器直接報錯拒絕）**：
  * `vscode`, `jupyter`, `rstudio`, `desktop`：`AllocNodes=stn[01-02]`，**僅限由 Open OnDemand (OOD) Web 介面一鍵啟動**。在 `ilgn01` 終端下達 `sbatch -p vscode` 會遭遇 `allocation failure: Access/permission denied`！
  * `visual-dev`, `visual`：`AllocNodes=intgpn[01-04]`，限專屬繪圖登入節點派送。
  * `arm-dev`, `arm144~arm1440`：`AllocNodes=nlgn[01-04]`，限 ARM 登入節點派送。

---

## 🚫 第二部分：不合理狀況檢測與防禦機制 (Guardrails)

AI 必須主動攔截並糾正以下「不合邏輯」或「必定失敗」的資源配置請求：

| 不合理狀況 (Fallacy) | 發生場景與危害 | AI 糾正與防禦措施 |
| :--- | :--- | :--- |
| **1. 100 核心配 1GB RAM** | 用戶誤以為「核心愈多跑愈快」，但程式為單執行緒或記憶體極小。在 `ct112` 上申請 100 核心會被系統鎖定 430 GB 記憶體配額，燃燒巨額計畫點數（SU），造成運算資源嚴重浪費。 | **主動介入說明**：「在國網 `ct112` 上申請 100 核心會自動綁定約 430 GB 記憶體。若您的程式是常規 Python 或未高度平行化，建議配置 2~4 核心即可（具備 8~17 GB RAM），避免浪費計畫 SU 點數。」 |
| **2. 4 核心硬要跑 200GB RAM** | 用戶在 `ct112` 薄節點上申請 4 核心（僅獲配 17.2 GB），卻執行 SPAdes 或大型矩陣，程式啟動幾分鐘內立刻因記憶體超出被 Linux Kernel 殺死 (`oom_kill`)。 | **主動介入說明**：「`ct112` 每核心僅配發 4.3 GB RAM，4 核心上限僅 17.2 GB。需要 200 GB 記憶體的任務請**改用大記憶體佇列 `cf112`** 並配置 24~28 核心（獲得約 214~250 GB RAM）！」 |
| **3. 單節點核心數 > 112** | 用戶寫 `#SBATCH -N 1 -c 128`。 | **指出硬體上限**：單一實體節點最多 112 核心。若需要超過 112 核心，程式必須具備分散式 MPI 平行架構，並配置跨節點分區 `ct448`。 |
| **4. 測試作業直接掛 96 小時** | 新手除錯腳本直接申請 `--time=96:00:00`，導致在佇列中排隊數小時甚至數天。 | **推薦測試佇列**：「首次測試腳本建議使用分區 `#SBATCH -p development`，時限設定 30 分鐘至 2 小時，享有最高優先權，幾乎秒排秒跑！」 |
| **5. 遺漏 `--account`** | 未指定計畫代號。國網中心排程器會強制攔截並終止提交。 | **強制要求指定**：必須於腳本標頭填入 `wallet` 查詢到的正數點數計畫代號（如 `#SBATCH -A GOV114022`）。 |
| **6. 日誌路徑目錄不存在** | 寫 `#SBATCH -o logs/job-%j.out` 但當前目錄沒有 `logs/` 資料夾，導致 Slurm 拋出 `_open_output_file: No such file or directory` 瞬間失敗。 | **推薦萬用 Token**：統一建議使用 `#SBATCH -o %x-%j.out` 與 `#SBATCH -e %x-%j.err`。 |

---

## 💬 第三部分：引導式問答流程 (Interactive Guided Questionnaire)

當使用者未提供完整規格時，AI **嚴禁盲目胡亂猜測**，應發起精準的「四步引導式提問」：

```markdown
您好！為了為您規劃最合適且符合國網創進一號（Taiwania 1）硬體規格的 Slurm 排程腳本，請協助提供以下 4 項資訊：

1. 💳 【計費計畫代號 (Account)】
   系統查詢到您帳號目前可用的計畫代號如下：
   - GOV114022 (剩餘額度: 1,682,178 SU)
   - GOV108018 (剩餘額度: 5,061,185 SU)
   - GOV109220 (剩餘額度: 424,225 SU)
   - GOV115071 (剩餘額度: 396,928 SU)
   請問此作業要從哪一個計畫代號扣抵？

2. 🔬 【運算軟體與任務類型】
   您預計執行的程式為何？
   (A) 常規 Python / R 數據分析 (輕中量級)
   (B) 生物資訊基因比對 / 質控 (如 FastQC, BWA, GATK)
   (C) 基因體組裝 / 大矩陣運算 (高記憶體需求，如 SPAdes, Trinity)
   (D) 跨節點平行運算 (MPI / OpenFOAM / VASP)
   (E) 批次多樣本平行 (Array Job)
   (F) 新腳本快速除錯測試 (推薦 development 佇列，8 小時內)

3. ⚡ 【預估 CPU 核心與記憶體需求】
   若您不清楚，請告知預估的記憶體用量，我們將為您換算最佳核心數：
   - 輕量型 (4 核 / ~17 GB RAM) ➔ 標準薄節點 `ct112`
   - 中量型 (8~16 核 / ~34~68 GB RAM) ➔ 標準薄節點 `ct112`
   - 重量型 (28~56 核 / ~250~500 GB RAM) ➔ 大記憶體 Fat Node `cf112`

4. ⏱️ 【運行時間預估 (Walltime)】
   預計作業需要執行多久？（建議為平常執行時間的 1.5~2 倍作為安全緩衝）
   是否需要設定作業完成或失敗時發送 Email 通報？
```

---

## 📊 第四部分：常見科研軟體建議規格速查表

若使用者指名特定軟體，直接依下表進行合理規格推薦：

| 軟體 / 任務類型 | 推薦佇列 (Partition) | 推薦 CPU 核心 | 獲得之記憶體 | 推薦時限預估 | 關鍵命令參數建議 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FastQC 質控** | `ct112` 或 `development` | 4 核心 | ~17.2 GB | 01:00:00 | `fastqc -t 4 input.fq.gz` |
| **MultiQC 整合** | `ct112` | 2 核心 | ~8.6 GB | 00:30:00 | `multiqc .` |
| **BWA-MEM 序列比對** | `ct112` | 16 ~ 28 核心 | ~68 ~ 120 GB | 06:00:00 | `bwa mem -t 16 ref.fa ...` |
| **SAMtools 排序建檔** | `ct112` | 8 ~ 16 核心 | ~34 ~ 68 GB | 03:00:00 | `samtools sort -@ 8 -m 4G` |
| **GATK HaplotypeCaller** | `ct112` (搭配 Array) | 4 ~ 8 核心 | ~17 ~ 34 GB | 08:00:00 | `gatk --java-options "-Xmx14G" ...` |
| **SPAdes 基因體組裝** | **`cf112` (Fat Node)** | **28 核心** | **~250 GB** | 24:00:00 | `spades.py -t 28 -m 240` |
| **Trinity 轉錄組組裝**| **`cf112` (Fat Node)** | **32 ~ 56 核心**| **~280 ~ 500 GB**| 48:00:00 | `Trinity --CPU 32 --max_memory 250G` |
| **Python 資料前處理** | `ct112` | 4 ~ 8 核心 | ~17 ~ 34 GB | 04:00:00 | 善用 `multiprocessing` |
| **Ollama / 本地 LLM** | `ct112` 或 `cf112` | 28 ~ 56 核心 | ~120 ~ 250 GB | 08:00:00 | CPU 推論線程綁定 |

---

## 🛠️ 第五部分：內建輔助工具與驗證流程

本技能隨附兩大自動化腳本（位於 `scripts/` 目錄）：

### 1. 查詢環境與可用額度 (`check_slurm_env.sh`)
```bash
bash <此 skill 的 scripts 目錄>/check_slurm_env.sh
```
即時輸出使用者的錢包餘額、有效計畫代號、以及 `development` / `ct112` / `cf112` 的閒置節點數。

### 2. 靜態分析與免扣點模擬預檢 (`validate_slurm.sh`)
在產生或修改任何 `.slurm` 腳本後，**必須引導使用者或主動執行驗證腳本**：
```bash
bash <此 skill 的 scripts 目錄>/validate_slurm.sh your_job.slurm
```
該工具會自動檢查：
- 是否缺少 Account 或填入無效 Account。
- 是否誤用受限 Partition（如 `vscode`、`visual`）。
- 是否有不合理的 CPU/記憶體比例（如 100 核心配 1G RAM）。
- 日誌資料夾是否存在。
- 最後調用 `sbatch --test-only` 取得 Slurm 排程器的官方預檢認證與預計啟動時間！

---

## 📝 第六部分：標準產出腳本品質規範

當確認好規格並產生 `.slurm` 腳本時，必須遵循以下品質要求：
1. **Shebang**：頂部標準 `#!/bin/bash`（單一行，無多餘重複）。
2. **完整標頭**：依序包含 `--account`、`--job-name`、`--partition`、`--nodes`、`--cpus-per-task`、`--time`、`--output`、`--error`。
3. **安全環境**：包含 `set -e` 與 `set -o pipefail`。
4. **即時診斷標頭**：在腳本開始執行時輸出 `date`、`hostname`、`SLURM_JOB_ID`、`SLURM_CPUS_PER_TASK`。
5. **軟體環境啟動**：指引載入 `module load` 或 `source /work1/.../bin/activate`。
6. **事後診斷提示**：提醒使用者作業結束後可用 `seff <job_id>` 檢視 CPU 與記憶體真實使用效率，以作為下次調整參數的依據。
