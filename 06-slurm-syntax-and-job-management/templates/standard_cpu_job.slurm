#!/usr/bin/env bash
#SBATCH --account=GOV114022           # (-A) iService 計費專案代號
#SBATCH --job-name=cpu_job            # (-J) 作業名稱
#SBATCH --partition=ct112             # (-p) 排程分區 (例如 ct112, development)
#SBATCH --nodes=1                     # (-N) 分配節點數
#SBATCH --ntasks-per-node=1           # 每個節點執行的 Task 數
#SBATCH --cpus-per-task=4             # (-c) 每個 Task 分配的 CPU 核心數
#SBATCH --time=01:00:00               # (-t) 最長運行時間 (時:分:秒 或 日-時:分:秒)
#SBATCH --output=%x-%j.out            # (-o) 標準輸出日誌 (%x=作業名稱, %j=作業ID)
#SBATCH --error=%x-%j.err             # (-e) 標準錯誤日誌
#SBATCH --mail-type=END,FAIL          # 郵件通知觸發時機 (BEGIN, END, FAIL, ALL)
##SBATCH --mail-user=your_email@example.com

# ==============================================================================
# standard_cpu_job.slurm - 標準 CPU 單節點批次作業範本
# 提交方式: sbatch standard_cpu_job.slurm
# ==============================================================================

echo "=========================================================="
echo "作業啟動時間 : $(date)"
echo "執行節點主機 : $(hostname -s)"
echo "Slurm 作業ID : ${SLURM_JOB_ID}"
echo "分配 CPU 核心: ${SLURM_CPUS_PER_TASK}"
echo "=========================================================="

# 1. 國網官方規範：第一行清空模組避免污染，再依需求載入對應環境
module purge
# module load gcc/8.5.0
# module load tools/miniconda3

# 2. 執行您的核心程式或運算
echo "==> 開始執行任務..."
# python3 my_script.py --threads "${SLURM_CPUS_PER_TASK}"

sleep 5

echo "=========================================================="
echo "作業順利完成時間: $(date)"
echo "=========================================================="
