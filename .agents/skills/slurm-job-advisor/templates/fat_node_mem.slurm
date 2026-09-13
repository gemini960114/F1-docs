#!/bin/bash
# ==============================================================================
# Slurm 批次排程範本：大記憶體運算 (Fat Node High-Memory Task)
# 適用於：SPAdes / Trinity / MEGAHIT 基因體組裝、大型矩陣分析、大數據 Pandas 等
# ==============================================================================
#SBATCH --account=GOV114022                  # 必填：wallet 查詢之可用計畫代號 (PROJECT_ID)
#SBATCH --job-name=fat_mem_task              # 作業識別名稱
#SBATCH --partition=cf112                    # 必選 cf112 (Fat Node，每核心提供高達 8.9 GB RAM)
#SBATCH --nodes=1                            # 單節點運算
#SBATCH --ntasks-per-node=1                  # 節點內行程數
#SBATCH --cpus-per-task=28                   # 28 核心 x 8.9 GB ≈ 250 GB RAM (可依需求調整 1~112 核)
#SBATCH --time=24:00:00                      # 運行時間上限 (cf112 最長支援 96 小時)
#SBATCH --output=%x-%j.out                   # 標準輸出
#SBATCH --error=%x-%j.err                    # 標準錯誤
#SBATCH --mail-type=END,FAIL                 # 通知時機
#SBATCH --mail-user=user@example.com         # 接收通報之 Email

set -e
set -o pipefail

echo "================================================================================"
echo "作業啟動時間 : $(date)"
echo "執行計算節點 : $(hostname -s)"
echo "作業任務 ID  : ${SLURM_JOB_ID}"
echo "分配 CPU 核心: ${SLURM_CPUS_PER_TASK}"
echo "分配記憶體   : 約 $(( SLURM_CPUS_PER_TASK * 8916 / 1024 )) GB"
echo "================================================================================"

# 執行大記憶體運算任務 (例如 SPAdes 組裝，記憶體上限設為 240 GB)
# spades.py -t ${SLURM_CPUS_PER_TASK} -m 240 -1 read_1.fq -2 read_2.fq -o spades_out/

echo "================================================================================"
echo "作業完成時間 : $(date)"
echo "================================================================================"
