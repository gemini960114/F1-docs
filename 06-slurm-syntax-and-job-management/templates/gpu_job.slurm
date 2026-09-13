#!/usr/bin/env bash
#SBATCH --account=GOV114022           # (-A) iService 計費專案代號
#SBATCH --job-name=gpu_job            # (-J) 作業名稱
#SBATCH --partition=visual-dev        # (-p) GPU 排程分區 (例如 visual-dev, visual)
#SBATCH --nodes=1                     # (-N) 分配節點數
#SBATCH --ntasks-per-node=1           # 每個節點執行的 Task 數
#SBATCH --cpus-per-task=14            # (-c) CPU 核心數
#SBATCH --gres=gpu:1                  # 申請的 GPU 數量 (Generic Resource)
#SBATCH --time=02:00:00               # 最長運行時間
#SBATCH --output=%x-%j.out            # 標準輸出日誌
#SBATCH --error=%x-%j.err             # 標準錯誤日誌

# ==============================================================================
# gpu_job.slurm - GPU 加速運算作業範本
# 提交方式: sbatch gpu_job.slurm
# ==============================================================================

echo "=========================================================="
echo "作業啟動時間 : $(date)"
echo "執行節點主機 : $(hostname -s)"
echo "Slurm 作業ID : ${SLURM_JOB_ID}"
echo "分配 GPU 資源: ${CUDA_VISIBLE_DEVICES:-'未指定'}"
echo "=========================================================="

# 1. 國網官方規範：第一行清空模組，載入 GPU/CUDA 工具
module purge
# module load nvidia/cuda/12.2

# 2. 檢查 GPU 狀態
if command -v nvidia-smi &>/dev/null; then
    nvidia-smi
fi

# 2. 執行 GPU 訓練或推論任務
echo "==> 開始執行深度學習任務..."
# python3 train.py

echo "=========================================================="
echo "GPU 作業完成時間: $(date)"
echo "=========================================================="
