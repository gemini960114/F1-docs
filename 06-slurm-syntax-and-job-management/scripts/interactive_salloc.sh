#!/usr/bin/env bash
# ==============================================================================
# interactive_salloc.sh - 一鍵啟動計算節點互動式除錯終端 (salloc + srun --pty)
# ==============================================================================
set -euo pipefail

ACCOUNT="${1:-GOV114022}"
PARTITION="${2:-development}"
CPUS="${3:-4}"
TIME_LIMIT="${4:-01:00:00}"

echo "========================================================"
echo "🚀 正在向 Slurm 申請互動式計算節點資源..."
echo "計畫代號 (Account)  : ${ACCOUNT}"
echo "申請佇列 (Partition): ${PARTITION}"
echo "分配核心 (CPUs)     : ${CPUS} (自動配發約 $((CPUS * 4300)) MB 記憶體)"
echo "時間上限 (Walltime) : ${TIME_LIMIT}"
echo "========================================================"
echo "提示: 進入節點終端後，測試完畢請輸入 exit 退出以停止計費。"
echo "--------------------------------------------------------"

# 透過 salloc 申請資源並立即以 srun 進入 bash
salloc \
  --account="${ACCOUNT}" \
  --partition="${PARTITION}" \
  --nodes=1 \
  --cpus-per-task="${CPUS}" \
  --time="${TIME_LIMIT}" \
  srun --pty /bin/bash
