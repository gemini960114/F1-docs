# HPC 實戰指南：創進一號 (f1) 遠端連線與雙因子認證 (SSH & 2FA)

歡迎來到高效能運算（HPC）的第一課！在開始使用超級電腦強大的 GPU/CPU 算力、搭建 VS Code 開發環境或提交 Slurm 排程前，第一道關卡就是：**如何安全連線進入國家高速網路與計算中心（NCHC）創進一號（Forerunner 1 / F1）超級電腦**。

本教學專門為初次使用國網中心 HPC 的研究員、工程師與學生設計，詳細解析帳號設定、雙因子認證（2FA）與檔案傳輸技巧。

> [!TIP]
> **🎯 本章在全系列中的定位：雲端工作台的一次性起跑 (One-Time Bootstrap)**  
> 您可能會好奇：「不是說全系列都使用 Code-Server 網頁版嗎？為什麼第 01 章還要教 SSH 與終端機連線？」  
> 原因有二：  
> 1. **帳號家目錄初始化**：國網中心官方規定，首次啟用帳號時，**必須先經由 SSH 登入過一次登入節點（`ilgn01`）**，系統才會自動建立您的 `$HOME` 目錄；若未執行此步驟，後續 Open OnDemand 與 Code-Server 會因無家目錄而無法開啟。  
> 2. **打造 Code-Server 的 Python 運算核心**：在本章第 8 節，我們將利用 `uv` 在 `/work1` 高速儲存區建立虛擬環境，這套環境正是第 03 章 Code-Server 中 Jupyter Notebook 所綁定的底層 Python Kernel！  
> **好消息**：這套 SSH 操作只是一次性設定，一旦第 03 章啟動 Code-Server，您將再也不需要本機終端機，全面常駐瀏覽器完成所有超算任務！

---

## 📌 目錄 (Table of Contents)
- [1. 叢集前門：四大前端伺服器架構與連線清單](#1-叢集前門四大前端伺服器架構與連線清單)
- [2. 前置準備：帳號申請與 IDExpert 2FA 綁定](#2-前置準備帳號申請與-idexpert-2fa-綁定)
- [3. SSH 登入實戰與三種雙因子驗證方式](#3-ssh-登入實戰與三種雙因子驗證方式)
- [4. 極速登入技巧：設定本地端 SSH Config](#4-極速登入技巧設定本地端-ssh-config)
- [5. 大檔案傳輸必備：資料傳輸節點 (DTN) 實作](#5-大檔案傳輸必備資料傳輸節點-dtn-實作)
- [6. 登入後第一步：環境健檢與三大儲存空間架構 (/home vs /work1)](#6-登入後第一步環境健檢與三大儲存空間架構-home-vs-work1)
- [7. HPC 軟體環境管理：Environment Modules (ml/module)](#7-hpc-軟體環境管理environment-modules-mlmodule)
- [8. 現代極速 Python 套件管理：uv 實務 (解決 Conda Inode 爆量痛點)](#8-現代極速-python-套件管理uv-實務-解決-conda-inode-爆量痛點)
- [9. 連線常見踩坑與排錯 (FAQ)](#9-連線常見踩坑與排錯-faq)

---

## 1. 叢集前門：四大前端伺服器架構與連線清單

> 參考官方技術手冊：[前端伺服器說明](https://man.twcc.ai/@f1-manual/Front_end_server) (最後更新：2025/07/01)

超級電腦為了防範網路攻擊、隔離運算與確保系統穩定，將外部連入節點（前端伺服器）劃分為**四大專用類型**：

```text
[ 使用者個人電腦 (Local PC/Laptop) ]
        │
        ├── 1. 登入節點 (Login: ilgn01/02, nlgn01/02) ────► 終端命令列 (SSH:22)，環境編譯與 Slurm 排程
        ├── 2. 資料傳輸節點 (DTN: dtn01/02) ──────────────► 專屬大檔案傳輸 (SFTP:22)，直通高速檔案系統
        ├── 3. 互動式繪圖節點 (GUI: intgpn01/02) ─────────► 2x NVIDIA A10 GPU，3D/桌面 (ThinLinc:1111)
        └── 4. 特殊工作流程節點 (OOD: stn01/02) ──────────► 瀏覽器 Web UI (HTTPS:443)，免打指令圖形化操作
```

### 官方前端伺服器完整連線資訊表 (Official Front-End Endpoints)

| 節點分類 | 節點代號 | 完整主機名稱 (FQDN) | IP 位址 | 服務 Port | 掛載目錄 / 適用架構 | 連線建議工具 |
| :--- | :---: | :--- | :--- | :---: | :--- | :--- |
| **登入節點**<br>(標準開發/排程) | `ilgn01`<br>`ilgn02` | `f1-ilgn01.nchc.org.tw`<br>`f1-ilgn02.nchc.org.tw` | `140.110.122.196`<br>`140.110.122.197` | **22 (SSH)** | **X86 架構**<br>`/home`(home1), `/work1`, `/project` | PuTTY, MobaXterm, 原生 Terminal |
| **登入節點**<br>(ARM 除錯) | `nlgn01`<br>`nlgn02` | `f1-nlgn01.nchc.org.tw`<br>`f1-nlgn02.nchc.org.tw` | `140.110.122.201`<br>`140.110.122.202` | **22 (SSH)** | **ARM 架構**<br>`/home`(home2), `/work2`, `/project` | PuTTY, 原生 Terminal |
| **資料傳輸節點**<br>(DTN 專用) | `dtn01`<br>`dtn02` | `f1-dtn01.nchc.org.tw`<br>`f1-dtn02.nchc.org.tw` | `140.110.122.210`<br>`140.110.122.211` | **22 (SFTP)** | **僅供傳檔，不開放 Shell 指令！**<br>`/home`, `/work1`, `/project` | WinSCP, FileZilla, Cyberduck |
| **互動式繪圖節點**<br>(3D 視覺化) | `intgpn01`<br>`intgpn02` | `f1-intgpn01.nchc.org.tw`<br>`f1-intgpn02.nchc.org.tw` | `140.110.122.206`<br>`140.110.122.207` | **1111 (ThinLinc)** | **搭載 2 張 NVIDIA A10 GPU**<br>支援 VirtualGL, ParaView 3D 模擬 | ThinLinc Client |
| **特殊工作流程**<br>(Open OnDemand) | `stn01`<br>`stn02` | `f1-stn01.nchc.org.tw`<br>`f1-stn02.nchc.org.tw` | `140.110.122.213`<br>`140.110.122.214` | **443 (HTTPS)** | **網頁圖形化門戶** (俄亥俄超算開源)<br>提供 Web Terminal, Job 管理, 檔案瀏覽 | Chrome, Edge 瀏覽器直連 |

> [!IMPORTANT]
> **官方新手必知黃金鐵律：**
> 1. **首次使用 Open OnDemand (OOD) 網頁服務前，請務必先透過 SSH 登入創進一號登入節點（`ilgn01` 或 `ilgn02`）一次！** 系統必須在 SSH 首次連入時為您初始化帳號家目錄（`$HOME`），否則網頁服務會因無家目錄而拋出異常。
> 2. **登入節點嚴禁重度運算**：所有登入節點均有 CPU 核心與記憶體配額限制，僅供編輯代碼與提交排程。大型運算請透過 Slurm 派送至計算節點。
> 3. **資料傳輸節點（DTN）僅供 SFTP**：請勿嘗試用 SSH 登入 DTN，連線會被直接拒絕。傳檔請一律走 DTN 以享有專屬高速頻寬。

---

## 2. 前置準備：帳號申請與 IDExpert 2FA 綁定

在連線前，請確認已完成以下 3 個步驟：

1. **註冊 iService 會員並加入計畫**：
   - 前往 [國網中心 iService 會員系統](https://iservice.nchc.org.tw/nchc_service/index.php) 註冊帳號。
   - 申請或加入具備創進一號計算額度的計畫（取得計畫代號，如 `GOV114022`）。
2. **啟用主機帳號與設定密碼**：
   - 在 iService 系統中建立 Linux 主機帳號（例如 `c00cjz00`），並設定強固密碼（英文大小寫、數字、特殊符號）。
3. **下載並綁定雙因子（2FA）App —— IDExpert**：
   - 創進一號強制要求雙因子認證以確保資安。
   - 請在手機 App Store / Google Play 下載安裝 **IDExpert**。
   - 依據 [iService 雙因子認證設定手冊](https://iservice.nchc.org.tw/nchc_service/nchc_service_qa_single.php?qa_code=774)，掃描 QR Code 完成與個人帳號綁定。

---

## 3. SSH 登入實戰與三種雙因子驗證方式

### A. 使用 macOS / Linux / Windows Terminal 命令列登入

在本地電腦打開終端機，執行連線指令（請將 `your_account` 替換為您的主機帳號）：

```bash
ssh your_account@f1-ilgn01.nchc.org.tw
```

首次連線時，終端機會詢問是否信任主機金鑰，請輸入 `yes`。

### B. 雙因子驗證交互流程（3 種方式）

連線建立後，系統會提示選擇 2FA 登入方式：

```text
Login method (1: Mobile APP OTP, 2: Mobile APP PUSH, 3: Email OTP): 
```

| 選項 | 方式名稱 | 操作步驟與注意事項 | 推薦度 |
| :---: | :--- | :--- | :---: |
| **`1`** | **Mobile APP OTP** | 輸入 `1` 後按下 Enter。打開手機 **IDExpert App**，點選左下角「**OTP**」，輸入畫面顯示的 6 位動態密碼。 | ⭐️⭐️⭐️⭐️ |
| **`2`** | **Mobile APP PUSH** | 輸入 `2` 後按下 Enter。手機 IDExpert App 會立刻收到「**授權請求**」推播，解鎖手機點擊「同意/打勾」即可自動通過！ | ⭐️⭐️⭐️⭐️⭐️<br>**(最推薦！)** |
| **`3`** | **Email OTP** | 輸入 `3` 後按下 Enter。至註冊信箱收取「登入驗證碼通知信」，輸入信中驗證碼。 | ⭐️⭐️⭐️<br>(備援方案) |

通過 2FA 認證後，終端機會提示輸入密碼：
```text
Password: 
```
輸入您在 iService 設定的主機密碼（輸入時螢幕不會顯示任何字元，此為 Linux 正常安全設計），按下 Enter 即可成功登入！

---

## 4. 極速登入技巧：設定本地端 SSH Config

每次都要打長串的主機名稱與帳號非常費時。您可以設定本地電腦的 SSH Config，將指令縮短為 `ssh f1`！

### 設定步驟（在您個人電腦執行）：

1. 在本地終端機編輯 `~/.ssh/config`（若檔案不存在會自動建立）：
   ```bash
   nano ~/.ssh/config
   ```
2. 貼上下列設定（本教學提供完整範本：[`config/ssh_config_example`](./config/ssh_config_example)）：
   ```sshconfig
    # 創進一號 (Forerunner 1 / F1) X86 登入節點
   Host f1
       HostName f1-ilgn01.nchc.org.tw
       User your_account
       Port 22
       ServerAliveInterval 60
       ServerAliveCountMax 3

   # 備援登入節點
   Host f1-02
       HostName f1-ilgn02.nchc.org.tw
       User your_account
       Port 22
   ```
3. 儲存退出（在 nano 按 `Ctrl+O` 儲存，`Ctrl+X` 退出）。
4. **一秒極速連線**：
   ```bash
   ssh f1
   ```
   只需輸入一個指令，即刻進入 2FA 驗證流程！

---

## 5. 大檔案傳輸必備：資料傳輸節點 (DTN) 實作

> [!CAUTION]
> **切勿在登入節點上傳/下載動輒數十 GB 的基因組或深度學習大資料集！**  
> 登入節點對外頻寬有限且多人共用。傳輸大型檔案請一律連線至專屬的高速資料傳輸節點（**Data Transfer Node, DTN**）。

### 傳輸節點連線資訊：
* **主機名稱**：`f1-dtn01.nchc.org.tw` (或 `140.110.122.210`)
* **通訊協定**：SFTP (Port 22)
* **注意**：DTN 節點不提供 Shell 互動命令列（下達 ssh 會直接關閉連線），專屬檔案傳輸使用。

### A. 使用圖形化工具 (FileZilla / WinSCP / Cyberduck)
* **主機 (Host)**：`f1-dtn01.nchc.org.tw`
* **通訊協定 (Protocol)**：SFTP - SSH File Transfer Protocol
* **連接埠 (Port)**：`22`
* **使用者帳號 / 密碼**：您的 iService 帳密與 2FA。
* 連線成功後，即可像操作本地資料夾一樣拖曳上傳/下載。

### B. 使用命令列快速傳輸 (rsync / scp)
從個人本機上傳資料夾至超級電腦的高速工作目錄：
```bash
# 使用 rsync 支援斷點續傳與進度顯示
rsync -avzP ./local_data/ your_account@f1-dtn01.nchc.org.tw:/work1/your_account/
```

從超級電腦下載分析結果到本地端：
```bash
rsync -avzP your_account@f1-dtn01.nchc.org.tw:/work1/your_account/results/ ./local_results/
```

---

## 6. 登入後第一步：環境健檢與三大儲存空間架構 (/home vs /work1)

登入成功後，請執行本章隨附的一鍵健康檢查腳本：

```bash
cd ~/hpc-tutorial/01-f1-ssh-and-2fa/scripts
./quick_healthcheck.sh
```

**輸出範例：**
```text
==========================================================
 🚀 創進一號 (f1) 登入節點環境健檢報告 (Login Node Healthcheck)
==========================================================

[1] 節點與系統資訊：
• 當前主機名稱 (Hostname) : ilgn01
• 登入使用者 (User)        : c00cjz00
• 作業系統版本 (OS)        : Red Hat Enterprise Linux 8.7 (Ootpa)
• CPU 核心數 (Cores)       : 112 核心
• 系統總記憶體 (Memory)    : 251Gi

[2] 計畫與 SU 錢包餘額 (wallet)：
PROJECT_ID: GOV114022, PROJECT_NAME: 國網計畫, SU_BALANCE: 2024

[3] 檔案儲存空間路徑確認：
• 家目錄 ($HOME)           : /home/c00cjz00 (檔案系統剩餘: 509T)
  ↳ ⚠️ 提醒: 上述為叢集總容量；個人/計畫配額請依 iService 申請為準 (GOV 類預設 100GB)
• 高速工作目錄 (/work1)   : /work1/c00cjz00 (高速運算主空間，GOV 預設 100GB，無備份)
• 計畫共用目錄 (/project) : 已掛載 (若計畫有額外申請共用空間請洽詢承辦)

[4] 登入節點外網連通性測試：
✅ 外網連線正常 (Hugging Face 連通)
✅ 外網連線正常 (GitHub 連通)
==========================================================
```

### B. 創進一號儲存空間架構：叢集總容量 vs 個人實際配額 (Quota)

> 參考官方技術手冊：[創進一號儲存架構與配額說明](https://man.twcc.ai/@f1-manual/storage)

許多初學者在終端機執行 `df -h` 時看到數百 TB，常誤以為自己擁有無限空間。**請務必分清「底層叢集硬體總量」與「帳號申請配額 (Quota)」的差別**：

| 儲存目錄路徑 | 叢集硬體總量 | 計畫/個人預設配額 | 主要用途 | 配額原則與最佳實踐 |
| :--- | :---: | :---: | :--- | :--- |
| **`/home/$USER`** (`$HOME`) | 0.5 PiB (共用) | **100 GB** | **個人原始碼、Git 倉庫、設定檔、小型腳本** | ⚠️ **強烈注意 Inode 限制**！嚴禁在此建立臃腫的 Conda 環境或存放數萬個小檔案，否則會觸發 `Disk quota exceeded`！ |
| **`/work1/$USER`** | 2.2 PB (共用) | **100 GB**<br>*(最高可申請至 200TB)* | **大型資料集、模型權重、Python 虛擬環境、分析輸出** | 🚀 **高效能運算主戰場**！具備超高 I/O 頻寬，大檔案與運算暫存請一律存放在此目錄。 |
| **`/project`** | 專案申請制 | 依計畫合約而定 | **計畫團隊共用資料庫、跨成員共享資料** | 官方基本空間以 `/home` 與 `/work1` 為主；若計畫有申請 `/project` 共用空間請洽詢國網承辦。 |

> [!CAUTION]
> **⚠️ 國網中心官方資料生命週期政策與重要備份警告 (必看！避免資料遺失)**：  
> 1. **28 天未存取自動清除**：官方明文規定，高速工作目錄（`/work1`）**「超過 28 天未存取的檔案將進入清除流程」**！請勿將 `/work1` 當作永久資料庫。  
> 2. **`/work1` 不提供備份**：官方明確宣告 **「`/work1` 不提供備份服務，資料遺失無法復原」**！重要代碼、研究成果與論文數據，必須定期備份回 `/home` 或經由 DTN 節點傳輸下載至個人本機保存。

> [!TIP]
> **HPC 空間使用黃金法則**：  
> 「**程式碼與 Git 倉庫放 `/home`，大資料與虛擬環境放 `/work1`，重要產出定期經 DTN 下載備份！**」

---

## 7. HPC 軟體環境管理：Environment Modules (ml/module)

> 參考官方技術手冊：[Modules 基本說明](https://man.twcc.ai/@f1-manual/modules_instructions)

在個人電腦上安裝軟體通常使用 `apt install` 或 `brew install`。但是在多人共用的超級電腦上，不同研究人員需要不同版本的 GCC 編譯器、CUDA、Python 或 OpenMPI。

為了實現**「多版本共存」**且**「不互相衝突干擾」**，超級電腦採用 **Environment Modules (模組化環境管理系統)**。它能動態修改使用者的 `$PATH`、`$LD_LIBRARY_PATH` 等環境變數，讓您一鍵切換開發工具！

> [!NOTE]
> 指令簡寫秘訣：系統提供 **`ml`** 作為 `module` 指令的極速簡寫（例如 `ml avail` 等同於 `module avail`）！

### A. 常用 Modules 核心指令速查表

| 完整指令 | 極速簡寫 (`ml`) | 功能說明 | 實戰範例 |
| :--- | :--- | :--- | :--- |
| `module avail` | `ml avail` | 列出目前環境所有可用的模組清單 | `ml avail` |
| `module list` | `ml` | 列出目前已載入的模組 | `ml` |
| `module spider <name>` | `ml spider <name>` | 全域深度搜尋指定模組（不論是否相依） | `ml spider python` |
| `module load <name>` | `ml <name>` | 載入指定的模組環境 | `ml gcc/8.5.0` |
| `module unload <name>` | `ml -<name>` | 卸載指定的模組 | `ml -gcc/8.5.0` |
| `module purge` | `ml purge` | **清空所有已載入模組 (徹底重設環境)** | `ml purge` |
| `module show <name>` | `ml show <name>` | 查看該模組會修改哪些系統路徑變數 | `ml show intel-oneapi` |

### B. 國網中心官方鐵律與避坑指南

1. **國網提交 Slurm 作業的第一黃金法則**：
   > ⚠️ **官方技術規範**：
   > 提交 Job Script（如 `.slurm` 批次檔）時，**請務必於執行內容的第一行加入 `module purge`，再依該 Job 需求載入對應模組！**  
   > 這樣能保證計算節點不受登入節點當前雜亂環境的污染，徹底杜絕因相依性引發的奇怪錯誤。
2. **階層式載入原則 (Hierarchical Loading)**：
   - 為了避免版本衝突，國網模組採階層式設計：**需先載入底層編譯器（如 `ml gcc/8.5.0`），系統才會開放顯示相容的上層函式庫（如 `openmpi/4.1.6`）**。
3. **路徑棄用提醒**：
   - `/pkg/x86/modulefiles` 僅供早期測試，自 **2024/06/24 正式上線後嚴禁使用**。請一律使用系統預設的標準模組庫。

### C. 實務操作示範腳本
本章隨附了模組操作示範腳本，可在登入節點直接執行觀察效果：
```bash
cd ~/hpc-tutorial/01-f1-ssh-and-2fa/scripts
./demo_modules.sh
```

---

## 8. 現代極速 Python 套件管理：uv 實務 (解決 Conda Inode 爆量痛點)

在超級電腦上做深度學習或資料分析，最忌諱使用傳統 `conda`。因為一個 Conda 環境往往產生 5 ~ 10 萬個零碎檔案，極易超過 HPC 系統的 **Inode 數量配額**。

### A. 為什麼在 HPC 推薦使用 `uv`？
* 🚀 **超快速度**：由 Rust 開發，解析依賴與下載套件速度比 `pip` / `conda` 快 **10 到 100 倍**。
* 📦 **單一執行檔**：無需管理員權限，不依賴龐大的 Python 執行階段。
* 💾 **保護 Inode**：智慧全域快取，避免重複複製檔案。

### B. 最佳實踐：環境與快取綁定 `/work1`

在 HPC 上使用 `uv` 時，務必將快取與虛擬環境建立在容量最大的高速儲存區（`/work1/$USER`）：

```bash
# 1. 指定快取目錄到 /work1 (可加入 ~/.bashrc 常駐)
export UV_CACHE_DIR="/work1/${USER}/.uv_cache"

# 2. 在 /work1 建立專屬虛擬環境 (秒級完成！)
uv venv /work1/${USER}/my_project_env

# 3. 安裝常用 AI / 資料分析套件
uv pip install --python /work1/${USER}/my_project_env/bin/python torch numpy pandas requests

# 4. 啟動環境
source /work1/${USER}/my_project_env/bin/activate
```

> [!TIP]
> 執行本章隨附的示範腳本，親自體驗 1 秒建立環境：
> ```bash
> cd ~/hpc-tutorial/01-f1-ssh-and-2fa/scripts
> ./demo_uv.sh
> ```

---

## 9. 連線常見踩坑與排錯 (FAQ)

### Q1：輸入 `ssh f1` 後一直卡住，連線超時 (Connection timed out)？
* **原因**：部分學術單位、公司內部網路或防火牆會阻擋對外的 Port 22 連線。
* **解法**：可嘗試切換為手機行動網路熱點連線，或向貴單位網管確認是否放行連往 `140.110.122.0/24` 的 22 埠。

### Q2：選擇 2. Mobile APP PUSH 後，手機一直沒收到推播？
* **原因**：手機省電模式攔截了推播通知，或手機網路不穩。
* **解法**：手動解鎖手機進入 **IDExpert App**，通常進入 App 畫面就會立刻跳出授權請求。若依然未收到，可按 `Ctrl+C` 中斷，重新連線並改選 **1. Mobile APP OTP** 輸入 6 位數。

### Q3：Permission denied (publickey,password) 密碼錯誤？
* **原因**：密碼輸入錯誤超過次數，或 iService 密碼已逾期需要重設。
* **解法**：登入 [iService 網頁](https://iservice.nchc.org.tw/) 確認密碼是否有效。若剛變更密碼，需等待約 5~10 分鐘同步至主機節點。

---

恭喜您！完成本章節後，您已經掌握了登入創進一號、儲存空間分配、模組管理 (`ml`) 與極速 Python 環境 (`uv`) 的必備技能！  
👉 **下一步**：進入 **[第 02 章：網頁服務反向代理與動態埠解析](../02-web-service-reverse-proxy/)**，學習如何突破超級電腦防火牆，在瀏覽器存取自己架設的網頁服務！
