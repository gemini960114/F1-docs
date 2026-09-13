# HPC 實戰指南：AI 輔助生醫管線 — FASTQ 下載與 FastQC / MultiQC 質控 (登入節點實作)

本教學手冊展示如何利用前幾章建立的 **VS Code Web (Code-Server)** 與 **AI 助手（Claude Code / Zoo Code / OpenCode）**，引導 AI 撰寫自動化腳本，在登入節點上下載 FASTQ 生醫定序資料並執行 **FastQC** 與 **MultiQC** 品質控制分析。

> [!IMPORTANT]
> **💡 跨領域通用學習聲明 (Case Study Disclaimer)**：  
> 本章以「生醫基因定序 FASTQ 質控」作為**具象化的端到端 (End-to-End) 數據處理示範案例**。  
> **非生醫背景的讀者請放心**：無論您的真實研究是**計算流體力學 (OpenFOAM)**、**分子動力學 (GROMACS/LAMMPS)**、**有限元素分析 (ANSYS)** 還是**深度學習模型訓練 (PyTorch)**，本章所傳授的：  
> 1. **如何給予 AI Agent 結構化 Prompt 自動產生處理流程**  
> 2. **如何在登入節點以小資料快速驗證管線邏輯 (Prototyping)**  
> 3. **如何利用反向代理在瀏覽器預覽互動式報表**  
> 
> 這套「**數據拉取 ➔ 批次分析 ➔ 結果可視化**」的核心架構與思維，在所有科學運算領域皆**100% 完全通用**！

---

## 📌 目錄 (Table of Contents)
- [1. 生醫資訊前處理概念：FASTQ、FastQC 與 MultiQC](#1-生醫資訊前處理概念fastqfastqc-與-multiqc)
- [2. 請 AI Agent 撰寫分析腳本 (Prompt 技巧)](#2-請-ai-agent-撰寫分析腳本-prompt-技巧)
- [3. 檔案結構與腳本說明](#3-檔案結構與腳本說明)
- [4. 實戰操作：在 Code-Server 整合終端機中執行質控流程](#4-實戰操作在-code-server-整合終端機中執行質控流程)
- [5. 與第 2 章反向代理聯動：在瀏覽器預覽 MultiQC 報告](#5-與第-2-章反向代理聯動在瀏覽器預覽-multiqc-報告)
- [6. 登入節點之限制與進入 Slurm 排程的必要性](#6-登入節點之限制與進入-slurm-排程的必要性)

---

## 1. 生醫資訊前處理概念：FASTQ、FastQC 與 MultiQC

在生物資訊（Bioinformatics）與次世代定序（NGS / 總體基因體學 16S / 宏基因組）研究中：

1. **FASTQ 檔案**：定序儀（如 Illumina、PacBio、ONT）輸出的標準格式，儲存每個 Read 的序列字母（A, T, C, G, N）以及對應的 Phred 品質分數（Quality Score）。
2. **FastQC**：針對單一 FASTQ 樣本進行品質檢驗，檢查項目包括：
   * Base Sequence Quality（鹼基品質分數曲線）
   * Per Base Sequence Content（ATCG 比例均衡度）
   * Per Sequence GC Content（GC 含量分佈，檢驗是否有外源污染）
   * Adapter Content（接頭序列殘留）
3. **MultiQC**：如果分析 30~100 個樣本，逐一查看 FastQC HTML 報告耗時費力。MultiQC 能夠**一鍵掃描整個目錄，將所有樣本的 FastQC 數據聚合為一份互動式網頁報告**！

---

## 2. 請 AI Agent 撰寫分析腳本 (Prompt 技巧)

在 Code-Server 中開啟 AI 助手（如 Claude Code 或 Zoo Code），輸入具體、具備架構要求的提示詞：

```text
你是一位熟悉生物資訊分析與 Linux HPC 環境的工程師。
我目前在 HPC 登入節點上，需要建立一套 FASTQ 資料前處理與品質控制（QC）管線。

請幫我編寫一個 Bash 腳本 `run_qc_pipeline.sh`，要求包含以下步驟：
1. 自動下載 QIIME 2 Moving Pictures 的示範 FASTQ 資料，存放在 `./fastq_raw/`。
2. 檢查 FastQC 與 MultiQC 是否已安裝，若無則自動調用 uv / 系統路徑載入。
3. 批次對 `./fastq_raw/` 下的所有 FASTQ 檔案執行 FastQC 分析，輸出至 `./fastqc_out/`。
4. 使用 MultiQC 彙整 `./fastqc_out/` 下的所有分析數據，生成 `./multiqc_out/multiqc_report.html`。
5. 包含完善的錯誤處理（set -euo pipefail），並在結尾輸出報告路徑。
```
*(完整提示詞可見 [`prompts/ai_prompt_bio_pipeline.md`](./prompts/ai_prompt_bio_pipeline.md))*

---

## 3. 檔案結構與腳本說明

```text
05-ai-assisted-bio-pipeline/
├── README.md                          # 本章完整教學手冊
├── prompts/
│   └── ai_prompt_bio_pipeline.md      # AI Agent 引導提示詞範本
├── scripts/
│   ├── download_demo_fastq.sh         # [1] 自動準備/取樣 4 組示範 FASTQ 檔案
│   ├── run_fastqc_multiqc.sh          # [2] 執行 FastQC 分析與 MultiQC 聚合
│   └── view_multiqc_report.sh         # [3] 透過 OOD 反向代理在瀏覽器即時預覽報告
└── demo_data/                         # 資料與報告存放區
    ├── fastq_raw/                     # 原始 FASTQ 檔案 (*.fastq.gz)
    ├── fastqc_out/                    # FastQC 輸出產物 (*_fastqc.zip)
    └── multiqc_out/                   # MultiQC 匯總產物 (multiqc_report.html)
```

---

## 4. 實戰操作：在 Code-Server 整合終端機中執行質控流程

請在 Code-Server 視窗中按下 **``Ctrl + ` ``** 展開整合式終端機，執行以下小規模原型驗證：

### 步驟 1：下載示範 FASTQ 資料
```bash
cd ~/hpc-tutorial/05-ai-assisted-bio-pipeline/scripts
bash download_demo_fastq.sh
```
此腳本會自動準備 4 組配對/單端測試樣本（`sample_01_R1.fastq.gz` ~ `sample_04_R1.fastq.gz`）。

### 步驟 2：執行質控管線
```bash
bash run_fastqc_multiqc.sh
```
**執行日誌輸出：**
```text
========================================================
🔬 [1/3] 檢查 FASTQ 原始資料與質控工具...
MultiQC 執行檔: ~/.venv-proxy/bin/multiqc
========================================================
🧬 [2/3] 執行 FastQC 品質控制分析...
========================================================
📊 [3/3] 執行 MultiQC 彙整產生單一 HTML 報告...
========================================================
/// MultiQC 🔍 v1.35
            fastqc | Found 4 reports
     write_results | Report : demo_data/multiqc_out/multiqc_report.html
           multiqc | MultiQC complete
--------------------------------------------------------
🎉 質控管線執行完畢！
MultiQC 報告位置: demo_data/multiqc_out/multiqc_report.html
```

> [!TIP]
> **工具環境相容說明**：
> 質控腳本 `run_fastqc_multiqc.sh` 具備自動環境偵測能力，會智慧尋找並相容：
> 1. 第 01 章建立的 Python 運算核心 (`/work1/$USER/envs/hpc-kernel`)
> 2. 第 07 章建立的代理環境 (`~/.venv-proxy`)
> 3. 或透過 `uv` 自動建立獨立質控環境 (`~/.venv-bio`)  
> 無論您是初次線性閱讀或跳章實作，皆可開箱即用、無縫執行！

---

## 5. 與第 2 章反向代理聯動：在瀏覽器預覽 MultiQC 報告

產生的 `multiqc_report.html` 位於遠端伺服器上。以往使用者需要透過 WinSCP 或 Cyberduck 下載回本機才能檢視，現在結合**第 2 章的反向代理技巧**，可在 1 秒內透過瀏覽器直接預覽！

```bash
bash ~/hpc-tutorial/05-ai-assisted-bio-pipeline/scripts/view_multiqc_report.sh
```
**輸出範例：**
```text
========================================================
📊 MultiQC HTML 報告預覽服務已啟動！
========================================================
主機節點 : ilgn01
分配埠號 : 45291
--------------------------------------------------------
👉 請在瀏覽器直接點擊此 OOD 反向代理網址檢視互動式報告：
   https://f1-stn01.nchc.org.tw/rnode/ilgn01/45291/multiqc_report.html
========================================================
```
點擊連結即可直接在個人電腦瀏覽器中操作互動式圖表、縮放品質曲線、下載統計圖檔！

---

## 6. 登入節點之限制與進入 Slurm 排程的必要性

在登入節點上執行小樣本（4 個樣本、幾千條 Reads）僅花費數秒鐘，是測試程式碼邏輯的極佳方式。

**然而，在真實科研專案中：**
* 真實樣本文庫通常有 **數十到數百個樣本**。
* 每個 FASTQ 壓縮檔動輒 **數百 MB 到數十 GB**。
* 若直接在登入節點執行大型 FastQC、BWA 比對或 QIIME 2 DADA2 去噪，會佔用高達數十個 CPU 核心與幾十 GB 記憶體，導致整台登入節點卡死，**會被系統管理員強制中止行程（`kill -9`）甚至暫停帳號權限**！

因此，我們必須學習如何使用 **Slurm 作業排程器**，將整個生醫分析流程封裝並派送到擁有龐大資源的**計算節點 (Compute Node)**。

> 💡 **學習脈絡導讀 (Roadmap)**：
> * **[第 06 章：Slurm 語法精講](../06-slurm-syntax-and-job-management/)**：您將深入掌握 Slurm 的核心指令（`sbatch`/`squeue`/`scancel`）、資源黃金三角配置與效能分析。
> * **[第 08 章：AI Agent 自動化排程實戰](../08-ai-agent-slurm-pipeline/)**：全系列集大成章節，您將看到 AI Agent 如何把本章（第 05 章）的生醫管線，無縫重構為 Slurm 批次作業並派送至計算節點大規模運算！

👉 **下一課**：[第 06 章：Slurm 語法精講與超級電腦作業調度實務](../06-slurm-syntax-and-job-management/)
