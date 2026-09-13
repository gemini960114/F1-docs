---
name: compute-node-proxy
description: >-
  Comprehensive guide, interactive decision engine, and automated diagnostic tool for establishing
  secure HTTP/HTTPS proxy tunnels between isolated HPC compute nodes (NCHC Taiwania 1 / f1) and the
  outside Internet via the login node. Detects network-dependent user tasks (pip, huggingface, wandb,
  git, API calls), conducts an interactive interview to differentiate offline pre-caching vs live
  proxying, audits login node proxy daemon status, prevents plaintext password leakage in `ps aux`,
  and auto-injects secure environment variables with fail-fast pre-flight connectivity checks into Slurm scripts.
---

# Compute Node Proxy & Network Tunnel Advisor (國網創進一號專用)

本技能（Skill）專門指導 AI Assistant 在超級電腦（HPC，特別是國網中心創進一號 Taiwania 1 / f1）環境中，處理**計算節點（Compute Node）實體網路隔離**與對外連網需求。

---

## 📌 核心觸發情境 (When to Activate)

當使用者在對話中提及以下任何需求時，**必須主動觸發本技能**：
1. **Slurm 腳本需要連網**：使用者要求在 Slurm 批次作業中下載資料、下載 Hugging Face / PyTorch 模型權重、安裝 Python 套件（`pip install`）。
2. **需要回傳即時監控數據**：程式碼使用 Weights & Biases (`wandb`)、MLflow、TensorBoard 遠端同步或串接外部 LLM / REST API（如 OpenAI、Anthropic、NCBI BLAST API）。
3. **遇到網路逾時錯誤**：使用者在計算節點（或 Slurm 作業日誌中）遇到 `Connection timed out`、`urllib3.exceptions.MaxRetryError`、`pip.exceptions.NetworkConnectionError`、`git: Could not resolve host`。

---

> 💡 **可攜性與腳本路徑說明**：本 Skill 所有輔助腳本皆位於此 Skill 自身安裝目錄的 `scripts/` 資料夾內（載入本 Skill 時系統會提供實際安裝路徑），完全獨立自足，不依賴任何特定使用者個人家目錄下的額外教學檔案。AI 產生 Slurm 腳本或給予執行指令時，務必將 Proxy 相關指令路徑替換為當次實際的 Skill 安裝路徑（以下範例以 `<此 skill 的 scripts 目錄>/xxx.sh` 表示），而非沿用固定字串。

## 🏛️ 第一部分：叢集真實網路架構與鐵律 (Truth & Constraints)

在給出任何排程與代碼建議前，AI **必須清楚認知超級電腦的網路拓撲**：

1. **計算節點（Compute Node）絕對無外網連線能力**：
   - 所有排程分區（`ct112`、`cf112`、`development` 等）均處於封閉內部網路，外部流量一律被防火牆阻斷。
   - **若未設定 Proxy，任何連外指令（`curl`、`pip`、`git`、`requests`）均會直接卡住並因逾時報錯**！
2. **登入節點（Login Node）具備外網，但嚴禁大算力運算**：
   - 登入節點（`ilgn01/02`）擁有對外網卡，可連通網際網路。
   - 我們透過在登入節點啟動 HTTP CONNECT 代理服務（`proxy.py` / `tinyproxy`），作為計算節點的流量轉發中繼站。
3. **必須使用真實 InfiniBand 內網 IP**：
   - 登入節點對計算節點的真實內網 IP 為 **`10.200.160.1`**（介面 `ib0`，走 InfiniBand 高速匯流排）。
   - **嚴格禁止使用網路上常見的假 IP**（如 `10.0.0.1`、`192.168.1.1` 或 `127.0.0.1`）！
4. **嚴格禁止明文密碼（防 `ps aux` 洩漏）**：
   - 國網中心為多人共用主機，將帳號密碼寫在指令列（如 `proxy --basic-auth user:pass`）或硬編碼在 `.slurm` 腳本中，會被其他使用者的 `ps aux` 完整看光！
   - 必須透過個人專屬權限檔案 **`~/.proxy_auth`（權限必須為 `600`）** 動態讀取載入。

---

## 🧭 第二部分：引導式問答決策流 (Interactive 4-Step Q&A)

當使用者欲在 Slurm 作業中涉及網路連線時，AI 應依序進行以下 4 步引導問答：

### 步驟 1：連網型態診斷（預載離線 vs 即時連網）
- **AI 提問範例**：
  > 「偵測到您的任務涉及外部網路連線（如下載模型/資料/套件）。請問這些資源**能否在登入節點預先下載至 `/work` 共享目錄**（強烈推薦），還是計算過程中**必須動態連線外網**（如 wandb 訓練監控、動態 API 請求）？」
- **判定準則**：
  - **若為靜態大檔（如 20GB 模型權重、大型 FASTQ/BAM 資料集）**：強烈建議先在登入節點下載好，計算節點以純離線方式讀取。避免百千核心作業同時透過登入節點下載導致頻寬塞車。
  - **若必須即時連網**：進入步驟 2。

### 步驟 2：登入節點 Proxy 狀態探測
- **AI 執行探測**：
  ```bash
  bash <此 skill 的 scripts 目錄>/check_proxy.sh
  ```
- **狀態分支判定**：
  - **若狀態為 🟢 運行中**：確認連接埠（預設 8888）與內網 IP（`10.200.160.1`），進入步驟 3。
  - **若狀態為 🔴 尚未啟動**：
    主動告知使用者：「登入節點的 Proxy 服務尚未啟動。請先執行以下指令啟動常駐代理：
    ```bash
    bash <此 skill 的 scripts 目錄>/start.sh
    ```
    完成後 AI 將為您配置排程腳本。」

### 步驟 3：安全憑證與環境變數規範
- 嚴禁在使用者產生的 Slurm 腳本中暴露任何明文密碼。
- 推薦注入方式（優先使用此 skill 安裝目錄下的環境載入腳本）：
  ```bash
  # 優先採用模組化載入腳本 (由 AI 動態填入實際安裝路徑)
  if [ -f "<此 skill 的 scripts 目錄>/set_compute_env.sh" ]; then
      source "<此 skill 的 scripts 目錄>/set_compute_env.sh"
  fi
  ```

### 步驟 4：外網連線防呆預檢（Fail-Fast 機制）
- **防止作業掛死白扣點數**：在 Slurm 腳本正式執行大算力計算前，**必須加入 5 秒連線快速預檢**。若連線失敗立即退出排程，避免因網路斷線導致核心空轉幾小時浪費計畫點數：
  ```bash
  if ! curl -s -I --connect-timeout 5 https://huggingface.co > /dev/null; then
      echo "❌ 錯誤：計算節點無法透過 Proxy 連線外網，請確認登入節點 Proxy 服務已啟動！"
      exit 1
  fi
  echo "✅ 外網連線正常，開始運算..."
  ```

### 步驟 5：作業完成後的 Proxy 收尾提醒 (Teardown & Cleanup)
- **主動巡檢與關閉**：Slurm 作業執行完成（無論成功或失敗）後，AI 應主動詢問使用者：
  > 「此次連網作業已完成，登入節點的 Proxy 服務目前仍在背景常駐運作（Port 8888）。是否需要現在關閉以釋放資源、降低暴露面？」
- **使用者確認後執行**：
  ```bash
  bash <此 skill 的 scripts 目錄>/stop.sh
  ```
- 若使用者預期近期還有其他連網作業要派送，可保留常駐，但仍應告知目前 Proxy 處於運行狀態。

---

## 🚫 第三部分：不合理狀況檢測與防禦機制 (Guardrails)

| 常見錯誤與反模式 | 發生危害 | AI 防禦與糾正動作 |
| :--- | :--- | :--- |
| **1. 誤以為計算節點有網路** | 在 `.slurm` 內直接寫 `pip install` 或 `wget`，排程提交後掛住 24 小時扣光點數。 | **主動介入**：「計算節點為實體隔離內網。若需連網，必須配置登入節點 Proxy 通道，或在登入節點先建立好 conda 虛擬環境。」 |
| **2. 使用假 IP (如 10.0.0.1)** | 網路上抄來的範例 IP 在創進一號根本不通。 | **強制校正**：「創進一號登入節點的 InfiniBand 內網 IP 為 `10.200.160.1`，已為您自動填入正確 IP。」 |
| **3. 在腳本寫入明文密碼** | `export http_proxy="http://user:Secret123@..."` 提交至 Slurm。 | **資安告警**：其他使用者透過 `ps aux` 即可看見明文密碼。強制要求使用 `~/.proxy_auth` 檔案動態讀取。 |
| **4. 遺漏或濫用 `no_proxy` 設定** | 未設 `no_proxy` 導致 MPI 崩潰；或濫用 `*.nchc.org.tw` 萬用字元導致連線公開站點（如 `www.nchc.org.tw` 官網）直連超時。 | **精確配置**：基礎內網直連設為 `export no_proxy="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12"`（已涵蓋叢集節點通訊）。<br>⚠️ **重要提醒**：`*.nchc.org.tw` 排除僅適用於已知的叢集內部主機名（如管理介面、儲存節點）。若目標是對外公開網站（如 `www.nchc.org.tw` 官網、任何需經由網際網路存取的頁面），應改用明確主機名清單，或直接從 `no_proxy` 移除該網域，確保流量走 Proxy 而非直連（計算節點無外網直連會導致連線逾時失敗）。 |
| **5. 忘記檢查登入節點 Proxy** | Slurm 任務已開始執行，但登入節點根本沒開 proxy，作業全面拋出連線例外。 | **腳本預檢**：在 Slurm 腳本頂部強制加入 `curl --connect-timeout 5` 預檢，斷線立即中止。 |

---

## 🛠️ 內建輔助腳本速查 (Tool Scripts)

```bash
# 1. 診斷登入節點 Proxy 是否在運作、IP 與認證是否正常
bash <此 skill 的 scripts 目錄>/check_proxy.sh

# 2. 在計算節點或 srun 終端中測試 Proxy 連線 (預設測 https://huggingface.co)
bash <此 skill 的 scripts 目錄>/test_compute_connection.sh

# 3. 啟動登入節點 Proxy 背景常駐 (tmux session)
bash <此 skill 的 scripts 目錄>/start.sh

# 4. 關閉登入節點 Proxy 背景常駐 (建議所有連網 Slurm 作業完成後主動詢問是否執行此腳本，而非讓 Proxy 無限期常駐)
bash <此 skill 的 scripts 目錄>/stop.sh
```
