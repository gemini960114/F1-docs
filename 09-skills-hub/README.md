# HPC AI Agent 技能總匯庫 (Skills Hub)

本目錄為國網中心創進一號（Taiwania 1 / f1）與通用 HPC 叢集量身設計的 **AI Agent 專家技能庫（Skills Hub）**。

透過將這些技能掛載至使用者的 Agent 環境（如 Google Antigravity、Claude Code、OpenCode、Zoo Code），AI 助手將從通用程式設計師，進化為**精通超級電腦排程、反向代理、資安規則與大數據管線的專屬專家**。

---

## 📦 技能庫清單 (Skills Catalog)

| 技能名稱 | 核心功能 | 適用場景 |
| :--- | :--- | :--- |
| **[`slurm-job-advisor`](./slurm-job-advisor/)** | • 讀取 `wallet` 計畫餘額<br>• 引導式 4 步問答需求挖掘<br>• 硬體約束防呆（杜絕「100核配1G RAM」）<br>• `sbatch --test-only` 免扣點預檢 | 使用者需要規劃、配置、診斷或撰寫 Slurm 排程腳本時 |
| **[`ai-agent-slurm-pipeline`](./ai-agent-slurm-pipeline/)** | • 互動式腳本自動重構為 Slurm 批次管線<br>• 純離線 (Case A) vs 動態 Proxy (Case B) 選型<br>• 多階段相依管線自動串接 (`--dependency=afterok:`) | 將 Code-Server/終端機執行的生醫或資料分析流程派送至計算節點時 |
| **[`web-service-reverse-proxy`](./web-service-reverse-proxy/)** | • Open OnDemand (`/rnode/<host>/<port>/`) 反向代理<br>• 動態連接埠分配（避免 `EADDRINUSE`）<br>• VS Code / Jupyter / Streamlit / Vite 背景常駐守護 | 在超級電腦上啟動各類 Web UI、API 服務與儀表板時 |

---

## 🚀 快速安裝與啟用

若要在目前帳號中啟用所有技能，只需執行隨附的同步腳本：

```bash
bash ~/hpc-tutorial/09-skills-hub/sync_skills.sh
```

執行後，所有技能將自動放置於 `~/.agents/skills/`，AI Agent 在啟動時會自動辨識並載入這些能力！

---

## 🛠️ 內建實用工具速查

```bash
# 1. 查詢 wallet 額度與可用佇列
bash ~/hpc-tutorial/09-skills-hub/slurm-job-advisor/scripts/check_slurm_env.sh

# 2. 驗證 Slurm 腳本合規性 (免扣點測試)
bash ~/hpc-tutorial/09-skills-hub/slurm-job-advisor/scripts/validate_slurm.sh your_script.slurm
```
