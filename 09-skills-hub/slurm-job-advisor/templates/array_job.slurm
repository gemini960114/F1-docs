#!/bin/bash
# ==============================================================================
# Slurm 批次排程範本：陣列平行批次作業 (Job Array)
# 適用於：批次處理數十至數千個獨立樣本 (如 FastQC 質控、基因比對、參數網格搜尋)
# ==============================================================================
#SBATCH --account=GOV114022                  # 必填：wallet 查詢之可用計畫代號 (PROJECT_ID)
#SBATCH --job-name=array_task                # 作業名稱
#SBATCH --partition=ct112                    # 佇列分區
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4                    # 每個子任務分配核心數
#SBATCH --time=02:00:00                      # 每個子任務的時限
#SBATCH --array=1-20%5                       # 總共 20 個子任務，%5 代表同時間最多平行跑 5 個
#SBATCH --output=slurm-%A_%a.out             # %A 為主作業 ID，%a 為子任務流水號 (1~20)
#SBATCH --error=slurm-%A_%a.err

set -e

echo "=== 啟動陣列子任務 ${SLURM_ARRAY_TASK_ID} on $(hostname -s) at $(date) ==="

# 依子任務 ID 從樣本文本讀取對應行數的樣本名稱
SAMPLE_FILE="samples.txt"
if [ -f "$SAMPLE_FILE" ]; then
    SAMPLE_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_FILE")
    echo "正在處理樣本: ${SAMPLE_NAME}"
    # 執行任務範例:
    # fastqc "${SAMPLE_NAME}.fastq.gz" -t ${SLURM_CPUS_PER_TASK} -o output/
else
    echo "⚠️ 找不到 $SAMPLE_FILE，以任務編號作為參數: ${SLURM_ARRAY_TASK_ID}"
fi

echo "=== 完成陣列子任務 ${SLURM_ARRAY_TASK_ID} at $(date) ==="
