# HPC 實戰指南：Slurm 語法精講與超級電腦作業調度實務

本教學手冊全面解析在國網中心（NCHC Taiwania）及各大超級電腦叢集中最核心的排程系統 —— **Slurm (Simple Linux Utility for Resource Management)**。

本章節基於您家目錄下的實戰腳本（涵蓋 CPU 運算、多陣列平行任務、GPU 加速等），進行系統化的語法剖析、架構指南與除錯清單。

---

## 📌 目錄 (Table of Contents)
- [1. 為什麼需要 Slurm？排程器運作本質](#_1-為什麼需要-slurm-排程器運作本質)
- [2. 創進一號 (Taiwania 1 / f1) 官方規格與佇列分區表](#_2-創進一號-taiwania-1-f1-官方規格與佇列分區表)
- [3. Slurm 核心參數速查表 (#SBATCH Directives)](#_3-slurm-核心參數速查表-sbatch-directives)
- [4. 資源配置黃金三角：Nodes、Tasks 與 CPUs](#_4-資源配置黃金三角-nodes、tasks-與-cpus)
- [5. 進階排程神器：陣列作業與流水線相依性](#_5-進階排程神器-陣列作業與流水線相依性)
  - [A. 陣列作業 (Array Jobs)](#a-陣列作業-array-jobs)
  - [B. 相依性作業 (Job Dependencies)](#b-相依性作業-job-dependencies)
  - [C. GPU 資源申請](#c-gpu-資源申請)
- [6. 作業監控、效能分析 (seff) 與資源除錯](#_6-作業監控、效能分析-seff-與資源除錯)
- [7. 範本與實用工具說明](#_7-範本與實用工具說明)
- [8. HPC 容器化技術：Singularity / Apptainer 實務](#_8-hpc-容器化技術-singularity-apptainer-實務)
- [9. 國網中心常見踩坑與排錯清單 (Troubleshooting)](#_9-國網中心常見踩坑與排錯清單-troubleshooting)

---

## 1. 為什麼需要 Slurm？排程器運作本質

在 HPC 叢集中：
* **數百位研究人員** 同時使用數百台高階伺服器（計算節點）。
* 若沒有排程機制，多人同時執行重度運算會導致記憶體耗盡（OOM）、CPU 搶佔，整個作業系統直接當機崩潰。

**Slurm 的核心任務：**
1. **佇列調度（Queueing）**：根據使用者的計畫配額（Account）與優先權分配節點。
2. **資源隔離（Cgroups Isolation）**：保證您申請的 4 核心或 1 張 GPU 完全歸您專屬獨佔，不會受到其他使用者程式干擾。
3. **作業計費（Accounting）**：精準計算使用的核心數與時間（SU 點數）。

> [!IMPORTANT]
> **🖥️ Code-Server 視角：為什麼在瀏覽器工作台中需要 Slurm？**  
> 1. **Code-Server 終端機運行在「登入節點」**：雖然在 Code-Server 寫程式極其方便，但登入節點是多人共用，嚴禁直接在 Code-Server 內建終端機執行多核心重度計算（如大數據質控、模型訓練），否則會造成節點卡死並被強制終止。  
> 2. **Code-Server 是最完美的「Slurm 指揮調度中心」**：  
>    * **撰寫**：在 Code-Server 編輯器中編寫 `.slurm` 腳本，享有語法高亮、排版與快速註解。  
>    * **派送**：在 Code-Server 整合式終端機（``Ctrl + ` ``）執行 `sbatch job.slurm`，將任務派往強大的計算節點。  
>    * **監控**：建議於作業腳本設定 Email 通知（`#SBATCH --mail-type=END,FAIL`），或在整合式終端機手動單次輸入 `squeue -u $USER` 查詢（⚠️ **官方明文嚴禁使用 watch 或迴圈高頻輪詢！**）。  
>    * **檢視**：作業完成後，直接在 Code-Server 檔案清單雙擊開啟 `slurm-*.out` 日誌，即時分析輸出！

---

## 2. 創進一號 (Taiwania 1 / f1) 官方規格與佇列分區表

> [!NOTE]
> 參考官方技術文件：[創進一號 Slurm 操作手冊](https://man.twcc.ai/@f1-manual/slurm_instructions) 與 [佇列分區表](https://man.twcc.ai/@f1-manual/partition)。

### A. 計畫錢包餘額查詢 (`wallet`) 與帳號綁定 (`-A` / `--account`)
在國網中心（Taiwania 1 / f1）送出任何 Slurm 批次或互動式作業前，**必須指定一個具備足夠點數的計畫代號（PROJECT_ID）**。

#### 1. 執行 `wallet` 指令查詢可用計畫與剩餘點數
系統於 `/etc/profile.d/wallet_func.sh` 提供了 `wallet` 查詢函式：
```bash
[user@ilgn01 ~]$ wallet
INFO: If you belong to many projects, it may take up to 5 seconds or more.
INFO: Specifying a project should be faster. `wallet $PROJECT_ID`
PROJECT_ID: GOV108018, PROJECT_NAME: 大數據平台服務組測試計畫, SU_BALANCE: 5061187.4165
PROJECT_ID: GOV114022, PROJECT_NAME: 可信賴雲TrustedCloud場域測試計畫, SU_BALANCE: 1682182.9089
PROJECT_ID: GOV109220, PROJECT_NAME: 動物試驗資料庫維護暨基因體分析建置, SU_BALANCE: 424296.1524
PROJECT_ID: GOV115071, PROJECT_NAME: 2026國研院暑期實習生專案計畫, SU_BALANCE: 396939.9041
PROJECT_ID: GOV115088, PROJECT_NAME: 國網生技醫藥高效能運算推廣與應用計畫, SU_BALANCE: 100990
PROJECT_ID: MST113173, PROJECT_NAME: 微生物相研究專案推動辦公室計畫(共同主持), SU_BALANCE: 2387.1999
```

> [!IMPORTANT]
> **關鍵綁定規則：**
> 1. **`SU_BALANCE` 必須為正數**：若該計畫點數為 `0` 或負數，Slurm 排程器將立即拒絕排程。
> 2. **在腳本中設定 `--account`**：將查得之 `PROJECT_ID` 填入 Slurm 腳本開頭：
>    ```bash
>    #SBATCH -A GOV114022
>    # 或
>    #SBATCH --account=GOV114022
>    ```
> 3. **常見錯誤**：若未指定計畫，或填入未授權/不存在的代號，送出作業時會報錯：
>    `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified`。

---

### B. 創進一號全分區清單與節點提交限制 (依據 `sinfo` 實機檢測)
創進一號每個計算節點最多配備 **112 顆 CPU 核心**，不同分區在硬體規格、記憶體配比與**提交節點權限 (AllocNodes)** 上有嚴格劃分：

#### 1. 登入節點 (`ilgn01/02`) 直接可派送之 CPU / 大記憶體佇列

| 佇列名稱 (Partition) | 節點規模與代號 | 記憶體配置標準 | 最長執行時間 | 適用場景與限制說明 |
| :--- | :--- | :--- | :--- | :--- |
| **`development`** | 28 節點 (`icpnp321-348`) | **4.3 GB / 核心** (4308 MB) | **8 小時** | **快速除錯測試**，優先權最高 (`PriorityJobFactor=1000`)，每用戶限 1 個 running 作業 |
| **`ct112`** (標準薄節點) | 336 節點 (`icpnq101-656`) | **4.3 GB / 核心** (4308 MB) | **96 小時** (4天) | **標準 CPU 單節點/小規模批次運算 (最常用)**，支援 1~112 核心 |
| **`ct448` ~ `ct8k`** | 336~390 節點 (`icpnq`) | 4.3 GB / 核心 | 48 ~ 96 小時 | 跨多節點大規模 MPI 平行運算 (依核心數規模選擇) |
| **`cf112`** (大記憶體 Fat Node) | 116 節點 (`icpnp101-310`) | **8.9 GB / 核心** (8916 MB) | **96 小時** (4天) | **高記憶體需求任務** (每節點約 1 TB RAM)，如大型基因體組裝、單細胞比對 |
| **`cf448` ~ `cf4k`** | 116 節點 (`icpnp`) | 8.9 GB / 核心 | 48 ~ 96 小時 | 跨多節點大記憶體 MPI 平行運算 |
| **`hm112` / `hm448`** (巨型記憶體) | 10 節點 (`icpnp311-320`) | **18.1 GB / 核心** (18130 MB)| **96 小時** (4天) | **超大記憶體任務** (每節點高達 2 TB RAM) |

#### 2. 受提交節點限制的分區 (⚠️ 從登入節點直接送出會報錯拒絕！)

| 佇列名稱 | 限制派送來源節點 (`AllocNodes`) | 錯誤症狀與正確使用方式 |
| :--- | :--- | :--- |
| **`vscode` / `jupyter` / `rstudio` / `desktop`** | `stn[01-02]` (OOD 專屬門戶節點) | 若在 `ilgn01` 輸入 `sbatch -p vscode` 會出現 **`allocation failure: Access/permission denied`**。此佇列為 Open OnDemand 網頁門戶內部專用，請由 OOD 介面一鍵啟動。 |
| **`visual-dev` / `visual`** (GPU 加速佇列) | `intgpn[01-04]` (繪圖專用登入節點) | 搭載 GPU 加速卡。需先登入繪圖前門節點 (`intgpn01~04`) 方可提交。 |
| **`arm-dev` / `arm144` ~ `arm1440`** (ARM 佇列) | `nlgn[01-04]` (ARM 專用登入節點) | 採用 ARM Fujitsu 處理器 (144 核/節點)。需由 ARM 登入節點 (`nlgn01~04`) 派送。 |

> [!TIP]
> **記憶體計算秘訣**：
> 在國網中心 Slurm 環境中，記憶體預設是根據申請的核心數按比例自動配發：
> * `ct112` 佇列：申請 4 核心（`--cpus-per-task=4`）自動配給約 `4 × 4.3GB = 17.2GB` 記憶體。
> * `cf112` 佇列：申請 4 核心自動配給約 `4 × 8.9GB = 35.6GB` 記憶體。
> * 若程式因 OOM 記憶體不足失敗，**請加大 `--cpus-per-task` 核心數**，或將 partition 改為 `cf112`！

---

### C. 語法除錯利器：正式派送前的預檢指令 (`--test-only`)
在正式提交作業消耗點數前，強烈建議使用 `--test-only` 測試您的腳本是否符合排程規則：
```bash
# 測試排程器是否接受該腳本（不消耗 SU、不真正排入佇列）
sbatch --test-only my_job.slurm
```
若語法與計畫皆正確，系統會立即回報預計開始執行的時間與分配節點：
```text
sbatch: Job 1073883 to start at 2026-09-13T19:03:13 using 4 processors on nodes icpnq101 in partition ct112
```
若有參數錯誤（如填錯 partition、帳號過期、超過佇列時限），則會立刻拋出明確錯誤提示，省去排隊除錯的時間！

---

## 3. Slurm 核心參數速查表 (#SBATCH Directives)

在批次腳本中，以 `#SBATCH` 開頭的行會被 Slurm 排程器解析：

| 參數語法 | 簡寫 | 功能說明 | 實戰範例 |
| :--- | :--- | :--- | :--- |
| `#SBATCH --account=<ID>` | `-A` | 指定計費計畫代號 (iService Project ID) | `--account=GOV114022` |
| `#SBATCH --job-name=<NAME>` | `-J` | 定義作業名稱 (顯示於 squeue) | `--job-name=fastqc_run` |
| `#SBATCH --partition=<NAME>` | `-p` | 指定排程分區 (Queue / Partition) | `--partition=ct112` |
| `#SBATCH --nodes=<N>` | `-N` | 申請的實體節點數量 | `--nodes=1` |
| `#SBATCH --ntasks-per-node=<N>` | | 每個節點執行的行程（Process/MPI）數 | `--ntasks-per-node=1` |
| `#SBATCH --cpus-per-task=<N>` | `-c` | 每個行程分配的 CPU 核心數（多執行緒） | `--cpus-per-task=4` |
| `#SBATCH --time=<D-HH:MM:SS>` | `-t` | 作業最長運行時間上限 (Walltime) | `--time=04:00:00` (4小時) |
| `#SBATCH --output=<FILE>` | `-o` | 標準輸出檔案路徑 | `--output=%x-%j.out` |
| `#SBATCH --error=<FILE>` | `-e` | 標準錯誤檔案路徑 | `--error=%x-%j.err` |
| `#SBATCH --mail-type=<TYPE>` | | 觸發 Email 通知的時機 | `--mail-type=END,FAIL` |
| `#SBATCH --mail-user=<EMAIL>` | | 接收通報的電子郵件信箱 | `--mail-user=user@gmail.com` |

> **日誌通配符（Tokens）說明**：
> * `%x`：作業名稱（Job Name）
> * `%j`：作業流水號 ID（Job ID）
> * `%A`：陣列作業主 ID
> * `%a`：陣列作業子任務序號

---

## 4. 資源配置黃金三角：Nodes、Tasks 與 CPUs

許多初學者容易混淆 `--nodes`、`--ntasks-per-node` 與 `--cpus-per-task`：

1. **單機多執行緒程式（如 Python multiprocessing, FastQC, OpenMP）**：
   * 範例：申請 1 節點、跑 1 個行程、使用 8 個執行緒。
   ```bash
   #SBATCH --nodes=1
   #SBATCH --ntasks-per-node=1
   #SBATCH --cpus-per-task=8
   ```
2. **多節點平行通訊（MPI 程式）**：
   * 範例：跨 2 台節點，每台節點跑 4 個 MPI Process。
   ```bash
   #SBATCH --nodes=2
   #SBATCH --ntasks-per-node=4
   #SBATCH --cpus-per-task=1
   ```

---

## 5. 進階排程神器：陣列作業與流水線相依性

### A. 陣列作業 (Array Jobs)
當有 50 個 FASTQ 檔案需要進行 FastQC 時，不需要手動寫 50 份 slurm 腳本，使用 `--array` 一鍵搞定！

```bash
#SBATCH --array=1-50%5       # 總共執行 50 個子任務，%5 代表最多同時平行執行 5 個
#SBATCH --output=logs/job-%A_%a.out

# 在程式碼中利用 ${SLURM_ARRAY_TASK_ID} 變數讀取第 N 個樣本：
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample_list.txt)
fastqc "fastq/${SAMPLE}.fastq.gz" -o fastqc_out/
```
*(參考範本：[`templates/array_job.slurm`](https://github.com/gemini960114/f1-docs/blob/main/06-slurm-syntax-and-job-management/templates/array_job.slurm))*

---

### B. 相依性作業 (Job Dependencies)
利用 `--dependency` 建立自動化工作流（Pipeline）：

```bash
# 步驟 1：送出下載任務
JOB1=$(sbatch --parsable download.slurm)

# 步驟 2：只有當下載成功 (afterok) 時，才開始執行質控
JOB2=$(sbatch --parsable --dependency=afterok:${JOB1} run_qc.slurm)

# 步驟 3：質控完成後，自動執行報告匯整
sbatch --dependency=afterok:${JOB2} multiqc.slurm
```
*(參考範本：[`templates/workflow_dependency.sh`](https://github.com/gemini960114/f1-docs/blob/main/06-slurm-syntax-and-job-management/templates/workflow_dependency.sh))*

---

### C. GPU 資源申請
在支援 GPU 的分區（如 `visual-dev`、`visual`）：
```bash
#SBATCH --partition=visual-dev
#SBATCH --nodes=1
#SBATCH --cpus-per-task=14
#SBATCH --gres=gpu:1          # 申請 1 顆 GPU
```
*(參考範本：[`templates/gpu_job.slurm`](https://github.com/gemini960114/f1-docs/blob/main/06-slurm-syntax-and-job-management/templates/gpu_job.slurm))*

---

### D. 互動式除錯與即時開發 (`salloc` 官方推薦)
當您需要即時排錯或測試程式，不想每次都透過 `sbatch` 提交批次檔時，可使用 `salloc` 直接調度一台計算節點並進入互動式 Shell：

```bash
# 1. 向 development 分區申請 1 台節點、4 核心的互動工作 (限時 1 小時)
salloc --account=GOV114022 --partition=development --nodes=1 --cpus-per-task=4 --time=01:00:00

# 2. 分配成功後，透過 srun 直接進入該計算節點的 Bash 終端：
srun --pty /bin/bash

# (此時 hostname 已經切換為計算節點，例如 icpnp305，可即時進行除錯或跑程式)

# 3. 測試完畢後退出 Shell，系統自動釋放資源並停止計費：
exit
exit
```
*(參考輔助腳本：[`scripts/interactive_salloc.sh`](https://github.com/gemini960114/f1-docs/blob/main/06-slurm-syntax-and-job-management/scripts/interactive_salloc.sh))*

---

## 6. 作業監控、效能分析 (seff) 與資源除錯

### A. 常用排程管理指令表

| 操作目標 | 指令語法 | 說明 |
| :--- | :--- | :--- |
| **提交作業** | `sbatch job.slurm` | 將作業送入排程佇列 |
| **查看個人作業** | `squeue -u $(whoami)` | 查詢排隊中 (`PD`) 或執行中 (`R`) 的任務 |
| **查看特定作業** | `squeue -j <JOB_ID>` | 查詢指定 ID 的作業狀態 |
| **取消單一作業** | `scancel <JOB_ID>` | 中止指定作業並釋放資源 |
| **取消個人所有作業** | `scancel -u $(whoami)` | 一鍵殺掉自己所有運行中的作業 |
| **查看作業詳細資訊** | `scontrol show job <JOB_ID>` | 查看工作目錄、節點分配、運行時間細節 |
| **查詢歷史作業紀錄** | `sacct -j <JOB_ID> --format=JobID,JobName,State,Elapsed,MaxRSS` | 查詢已結束作業的記憶體峰值 (MaxRSS) 與退出碼 |
| **查詢分區空閒狀態** | `sinfo -s` | 查看各 Queue 節點空閒狀況 (idle / alloc) |

> [!WARNING]
> **⚠️ 國網中心官方鐵律：嚴禁使用 `watch` 或程式迴圈高頻輪詢 `squeue`！**  
> 官方「初次使用須知」明文嚴正警告：**「禁用 watch 指令或程式迴圈搭配 squeue 的做法，這會增加排程系統負擔。建議改用電子郵件通知機制。」**  
> 推薦在批次腳本中加入以下設定，讓超算系統於作業結束時主動通知您：
> ```bash
> #SBATCH --mail-type=END,FAIL
> #SBATCH --mail-user=your_email@domain.com
> ```
> 若需手動確認狀態，偶爾執行單次 `squeue -u $(whoami)` 即可，**切勿使用 watch 進行無休止的高頻輪詢**！


### B. 核心效能診斷神器：`seff` (避免浪費計畫點數)

作業執行完畢後，執行官方效能分析工具：
```bash
seff <JOB_ID>
```

**輸出範例解密：**
```text
Job ID: 1073764
State: COMPLETED (exit code 0)
CPU Utilized: 00:03:12
CPU Efficiency: 80.00% of 00:04:00 core-walltime
Memory Utilized: 2.15 GB
Memory Efficiency: 12.50% of 17.20 GB
```

**🔍 兩大常見資源浪費與除錯解法：**
1. **CPU 效率太低 (CPU Efficiency < 20%)**：
   - **原因**：申請了多核心（例如 `--cpus-per-task=16`），但執行之程式僅支援單執行緒（未開平行化），白白浪費了 15 核心的 SU 計費點數！
   - **優化**：調降申請核心數為 1 或 2，或修改程式加入 multiprocessing / OpenMP 平行加速。
2. **記憶體溢出崩溃 (OOM - Out of Memory, ExitCode 137)**：
   - **原因**：程式使用的記憶體超過了申請的配額，被 Linux 核心 OOM Killer 強制殺死。
   - **解法**：在 `ct112`（每核心 4.3GB）下加大 `--cpus-per-task` 獲取更多記憶體，或者直接切換至大記憶體專用分區 **`#SBATCH --partition=cf112`（每核心提供高達 8.9 GB 記憶體）**！

---

## 7. 範本與實用工具說明

本教學模組在 `templates/` 與 `scripts/` 中提供現成範本：

```text
06-slurm-syntax-and-job-management/
├── README.md                          # 本語法指南
├── templates/
│   ├── standard_cpu_job.slurm         # [1] 標準單節點 CPU 作業範本 (含 module purge)
│   ├── gpu_job.slurm                  # [2] GPU 運算作業範本 (--gres=gpu:1)
│   ├── array_job.slurm                # [3] 批次陣列平行作業範本 (--array)
│   ├── workflow_dependency.sh         # [4] 自動流水線相依性串接範例
│   └── singularity_job.slurm          # [5] 容器化運算批次作業範本 (Singularity/Apptainer)
└── scripts/
    ├── slurm_status.sh                # 快速查詢個人作業與分區狀態小工具
    └── interactive_salloc.sh          # 官方標準互動式除錯登入腳本
```

---

## 8. HPC 容器化技術：Singularity / Apptainer 實務

> 參考官方技術手冊：[創進一號 Singularity 容器使用說明](https://man.twcc.ai/@f1-manual/manual)

在 HPC 多用戶叢集中，基於資安考量嚴禁使用 Docker（因為需要 root 權限）。**Singularity (Apptainer)** 是超級電腦上唯一被廣泛採用的無 root 容器技術！

### A. 常用指令快速上手
* **將 Docker 鏡像轉換為單一 SIF 檔**：
  ```bash
  # 拉取官方 Ubuntu 鏡像並轉為 ubuntu_22.04.sif
  singularity pull ubuntu_22.04.sif docker://ubuntu:22.04
  ```
* **在容器中執行指令 (掛載 `/work1` 目錄)**：
  ```bash
  singularity exec -B /work1/${USER}:/mnt ubuntu_22.04.sif python3 /mnt/script.py
  ```
* **GPU 深度學習支援 (啟用 `--nv`)**：
  ```bash
  singularity exec --nv -B /work1/${USER}:/mnt pytorch_latest.sif python3 -c "import torch; print('GPU 可用:', torch.cuda.is_available())"
  ```

### B. 在 Slurm 批次作業中呼叫容器
請參考本章隨附範本 [`templates/singularity_job.slurm`](https://github.com/gemini960114/f1-docs/blob/main/06-slurm-syntax-and-job-management/templates/singularity_job.slurm)，只需一行即可在計算節點上以指定容器無縫執行運算！

---

## 9. 國網中心常見踩坑與排錯清單 (Troubleshooting)

### Q1: 作業狀態一直顯示 `PD` (Pending)，原因為 `Resources` 或 `Priority`
* **原因**：目前分區中所有節點已被佔滿，或有其他優先權更高的任務在排隊。
* **應對**：若只是想快速測試程式邏輯，可考慮將時間設定縮短，或切換至測試分區（如 `development`）。

### Q2: 提交時報錯 `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified`
* **原因**：您的計畫代號（Account）沒有該分區（Partition）的使用權限，或是專案已過期。
* **查詢可用 Account 指令**：
  ```bash
  sacctmgr show user $(whoami) withassoc format=Account,Partition
  ```

### Q3: 作業瞬間失敗，日誌中出現 `slurmstepd: error: _open_output_file: No such file or directory`
* **原因**：在 `#SBATCH --output=logs/job-%j.out` 中指定了子目錄 `logs/`，但執行 `sbatch` 的當下目錄沒有這個資料夾！
* **解法**：在腳本開頭加上 `mkdir -p logs`，或直接使用 `%x-%j.out` 避免目錄依賴。

---

👉 **下一課**：[第 07 章：突破網路隔離 — 計算節點安全聯網代理 (HTTP Proxy)](./07_compute_node_proxy)
