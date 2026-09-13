# AI 提示詞範本：請 AI Agent 將互動管線重構為 Slurm 批次作業

您可以直接複製以下提示詞，貼給 VS Code 中的 AI 助手（例如 **Claude Code**、**Zoo Code** 或 **OpenCode**），讓 AI 自動將本機腳本轉化為高可靠度的 Slurm 批次作業：

---

### 📋 提示詞內容 (Prompt Template)

```text
你是一位熟悉超級電腦 Slurm 排程器與生物資訊分析的專家。
我原本在登入節點有一個執行 FASTQ 質控分析（FastQC + MultiQC）的互動腳本 `run_fastqc_multiqc.sh`。
現在我希望將這套流程改由 Slurm 佇列派送到計算節點（Compute Node）執行。

請幫我編寫兩個版本的 Slurm 批次作業腳本（符合國網中心 NCHC 規格，使用 #SBATCH --account=GOV114022 與 --partition=ct112）：

【版本一：事前下載 / 離線運算模式】
- 假設資料已在登入節點下載完畢，存放在共用目錄。
- Slurm 腳本在計算節點上純離線運行，分配 4 個 CPU 核心與 1 小時上限。
- 自動處理 FastQC 多核心平行處理與 MultiQC 匯總。
- 日誌輸出需使用 `%x-%j.out` 避免目錄相依性問題。

【版本二：動態掛載 HTTP Proxy 運算模式】
- 計算節點預設沒有對外網路，但登入節點有開啟 HTTP Proxy (10.200.160.1:8888)。
- Slurm 腳本需在開頭載入 `set_compute_env.sh` 設定環境變數。
- 在計算節點上即時透過網路下載 FASTQ 資料（或模型），接著立即進行 FastQC 與 MultiQC 分析。
- 請加入連線錯誤處理，並確保 no_proxy 排除叢集內網節點。

請提供結構清晰、包含完整註解的 `.slurm` 腳本以及提交指令。
```
