# Slurm Job Advisor & Resource Sizing Skill

針對國網中心創進一號（Taiwania 1 / f1）超級電腦與通用 HPC Slurm 叢集量身打造的**資源規劃與排程腳本專家技能**。

---

## 🎯 核心功能

1. **動態錢包與佇列整合**：直接讀取國網 `wallet` 計畫餘額，確保作業指定具有足夠 SU 點數的帳號。
2. **防呆與不合理狀況攔截**：杜絕「100 核心配 1GB RAM」或「在薄節點跑超大記憶體任務導致 OOM」等不合理配置。
3. **結構化引導問答**：當使用者未提供完整需求時，發起 4 步結構化提問（計畫代號、軟體類型、資源規模、時間預估）。
4. **全流程驗證工具**：內建免扣點排程器預檢腳本（`sbatch --test-only`），提交前 100% 確保語法與配額合規。

---

## 📁 目錄結構

```text
slurm-job-advisor/
├── SKILL.md                          # 核心技能指引、問答模板與硬體規格矩陣
├── README.md                         # 說明文件
├── scripts/
│   ├── check_slurm_env.sh            # 查詢 wallet 餘額與登入節點佇列即時狀態
│   └── validate_slurm.sh             # 靜態參數分析 + sbatch --test-only 免扣點預檢
└── templates/
    ├── single_node_cpu.slurm         # 常規單節點多執行緒腳本範本 (ct112)
    ├── fat_node_mem.slurm            # 高記憶體組裝/大數據腳本範本 (cf112)
    └── array_job.slurm               # 多樣本批次平行陣列腳本範本
```

---

## 🚀 快速指令

### 1. 查詢環境與錢包額度
```bash
bash ~/.agents/skills/slurm-job-advisor/scripts/check_slurm_env.sh
```

### 2. 驗證 Slurm 腳本
```bash
bash ~/.agents/skills/slurm-job-advisor/scripts/validate_slurm.sh <your_job.slurm>
```
