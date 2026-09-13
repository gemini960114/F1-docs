# HPC AI Agent 技能總匯庫 (Skills Hub)

本目錄為國網中心創進一號（Forerunner 1 / F1）與通用 HPC 叢集量身設計的 **AI Agent 專家技能庫（Skills Hub）**。

透過將這些技能掛載至使用者的 Agent 環境（如 Google Antigravity、Claude Code、OpenCode、Zoo Code），AI 助手將從通用程式設計師，進化為**精通超級電腦排程、反向代理、資安規則與大數據管線的專屬專家**。

---

## 📦 技能庫清單 (Skills Catalog)

| 技能名稱 | 核心功能 | 適用場景 |
| :--- | :--- | :--- |
| **[`slurm-job-advisor`](./slurm-job-advisor/)** | • 讀取 `wallet` 計畫餘額<br>• 引導式 4 步問答需求挖掘<br>• 硬體約束防呆（杜絕「100核配1G RAM」）<br>• `sbatch --test-only` 免扣點預檢 | 使用者需要規劃、配置、診斷或撰寫 Slurm 排程腳本時 |
| **[`compute-node-proxy`](./compute-node-proxy/)** | • 計算節點實體隔離外網穿透<br>• 引導式 4 步連網型態與 Proxy 診斷<br>• 安全憑證防護（杜絕 `ps aux` 明文洩漏）<br>• `curl --connect-timeout 5` 連線防呆預檢 | 計算節點需要下載模型/套件、連線 wandb 或呼叫外部 API 時 |
| **[`ai-agent-slurm-pipeline`](./ai-agent-slurm-pipeline/)** | • 互動式腳本自動重構為 Slurm 批次管線<br>• 純離線 (Case A) vs 動態 Proxy (Case B) 選型<br>• 多階段相依管線自動串接 (`--dependency=afterok:`) | 將 Code-Server/終端機執行的生醫或資料分析流程派送至計算節點時 |
| **[`web-service-reverse-proxy`](./web-service-reverse-proxy/)** | • Open OnDemand (`/rnode/<host>/<port>/`) 反向代理<br>• 動態連接埠分配（避免 `EADDRINUSE`）<br>• VS Code / Jupyter / Streamlit / Vite 背景常駐守護 | 在超級電腦上啟動各類 Web UI、API 服務與儀表板時 |

---

## 🚀 快速安裝與啟用

### 方法一：現代標準 `npx skills add` 一鍵安裝 🌟 (最推薦)

```bash
# 一鍵全域安裝所有技能 (~/.agents/skills/)
npx -y skills add gemini960114/F1-docs -g -y
```

### 方法二：創進一號叢集本機同步腳本

若要在目前帳號中啟用所有技能，只需執行隨附的同步腳本：

```bash
bash ~/hpc-tutorial/09-skills-hub/sync_skills.sh
```

執行後，所有技能將自動放置於 `~/.agents/skills/`，AI Agent 在啟動時會自動辨識並載入這些能力！

---

## 🛠️ 內建實用工具速查

```bash
# 1. 查詢 wallet 額度與可用佇列 (slurm-job-advisor)
bash ~/.agents/skills/slurm-job-advisor/scripts/check_slurm_env.sh

# 2. 驗證 Slurm 腳本合規性 (免扣點測試) (slurm-job-advisor)
bash ~/.agents/skills/slurm-job-advisor/scripts/validate_slurm.sh your_script.slurm

# 3. 診斷登入節點 Proxy 狀態與內網 IP (compute-node-proxy)
bash ~/.agents/skills/compute-node-proxy/scripts/check_proxy.sh

# 4. 啟動與關閉登入節點 Proxy 常駐服務 (compute-node-proxy)
bash ~/.agents/skills/compute-node-proxy/scripts/start.sh
bash ~/.agents/skills/compute-node-proxy/scripts/stop.sh

# 5. 測試計算節點代理連通性 (compute-node-proxy)
bash ~/.agents/skills/compute-node-proxy/scripts/test_compute_connection.sh
```

---

## 💡 四大技能實戰對話範例 (Interactive Walkthrough)

想了解 AI Agent 如何在真實 HPC 情境中靈活運用這 4 大技能進行多輪問答引導、資源規劃防呆、憑證保護與錯誤排查？

👉 請參閱官方完整教學手冊：  
**[第 09 章：HPC AI Agent 技能總匯庫 第 8 節實戰範例](../../guide/09_hpc_skills_hub.html#_8-四大-hpc-ai-agent-skills-實戰對話範例-4-round-interactive-walkthrough)**

