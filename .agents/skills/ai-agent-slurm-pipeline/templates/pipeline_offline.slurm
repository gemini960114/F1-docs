#!/bin/bash
# ==============================================================================
# Slurm 管線範本：純離線重度運算模式 (Case A: Pre-staged Offline Execution)
# 適用於：資料/模型已預先存放於 /work1 儲存區，計算節點純離線高速運算
# ==============================================================================
#SBATCH --account=GOV114022                  # 必填：有效計畫代號
#SBATCH --job-name=offline_pipeline          # 作業名稱
#SBATCH --partition=ct112                    # 佇列分區
#SBATCH --nodes=1                            # 節點數
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4                    # 核心數
#SBATCH --time=02:00:00                      # 時限
#SBATCH --output=%x-%j.out                   # 輸出日誌
#SBATCH --error=%x-%j.err                    # 錯誤日誌

set -euo pipefail

echo "================================================================================"
echo "作業啟動時間 : $(date)"
echo "執行計算節點 : $(hostname -s)"
echo "作業任務 ID  : ${SLURM_JOB_ID}"
echo "分配 CPU 核心: ${SLURM_CPUS_PER_TASK}"
echo "工作目錄     : $(pwd)"
echo "================================================================================"

# 檢查輸入檔案是否存在
INPUT_DIR="/work1/${USER}/data"
if [ ! -d "$INPUT_DIR" ]; then
    echo "⚠️ 找不到資料目錄 $INPUT_DIR，請先於登入節點完成資料下載與準備。"
fi

# 執行分析運算 (多核心平行處理)
echo "正在執行核心分析管線..."
# python3 analyze.py --threads "${SLURM_CPUS_PER_TASK}"

echo "================================================================================"
echo "作業完成時間 : $(date)"
echo "================================================================================"
