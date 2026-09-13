#!/usr/bin/env bash
#SBATCH --account=GOV114022           # (-A) iService 計費專案代號
#SBATCH --job-name=singularity_job    # (-J) 作業名稱
#SBATCH --partition=ct112             # (-p) 排程分區
#SBATCH --nodes=1                     # (-N) 節點數
#SBATCH --ntasks-per-node=1           # Task 數
#SBATCH --cpus-per-task=4             # (-c) 核心數
#SBATCH --time=01:00:00               # (-t) 執行時間上限
#SBATCH --output=%x-%j.out            # (-o) 標準輸出
#SBATCH --error=%x-%j.err             # (-e) 標準錯誤

# ==============================================================================
# singularity_job.slurm - 在 Slurm 計算節點運行 Singularity 容器作業範本
# 提交指令: sbatch singularity_job.slurm
# ==============================================================================

echo "=========================================================="
echo "作業啟動時間 : $(date)"
echo "執行計算節點 : $(hostname -s)"
echo "作業流水號   : ${SLURM_JOB_ID}"
echo "=========================================================="

# 1. 【國網規範】重設模組環境
module purge

# 2. 定義容器映像檔位置與工作目錄 (建議放在大容量 /work1)
SIF_IMAGE="${HOME}/ubuntu_22.04.sif"
WORK_DIR="/work1/${USER}"

# 3. 若容器檔不存在，示範從 Docker Hub 自動拉取轉為 SIF (離線模式請先備妥)
if [ ! -f "${SIF_IMAGE}" ]; then
    echo ">> 映像檔不存在，嘗試拉取 (需外網或已事先準備)..."
    # singularity pull "${SIF_IMAGE}" docker://ubuntu:22.04
fi

# 4. 在計算節點執行容器 (掛載 /work1 目錄，若有 GPU 加上 --nv 參數)
echo "==> 啟動 Singularity 容器執行任務..."
# singularity exec -B "${WORK_DIR}":/mnt "${SIF_IMAGE}" python3 /mnt/script.py

# 示範查看容器系統版本
if command -v singularity &>/dev/null; then
    singularity --version
    echo "✅ Singularity 環境就緒！"
fi

echo "=========================================================="
echo "作業順利完成時間: $(date)"
echo "💡 提示：作業結束後可透過 seff ${SLURM_JOB_ID} 查看資源利用率！"
echo "=========================================================="
