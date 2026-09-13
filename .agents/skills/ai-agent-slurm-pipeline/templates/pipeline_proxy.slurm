#!/bin/bash
# ==============================================================================
# Slurm 管線範本：動態掛載 HTTP Proxy 即時下載模式 (Case B: Dynamic Proxy Execution)
# 適用於：計算節點需即時下載資料、拉取模型或調用外部 API
# ==============================================================================
#SBATCH --account=GOV114022                  # 必填：有效計畫代號
#SBATCH --job-name=proxy_pipeline            # 作業名稱
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
echo "================================================================================"

# ------------------------------------------------------------------------------
# 1. 掛載登入節點之 HTTP Proxy 隧道環境變數
# ------------------------------------------------------------------------------
PROXY_ENV="$HOME/hpc-tutorial/07-compute-node-proxy/scripts/set_compute_env.sh"
if [ -f "$PROXY_ENV" ]; then
    echo "正在載入 Proxy 環境變數: $PROXY_ENV"
    # shellcheck source=/dev/null
    source "$PROXY_ENV"
else
    echo "⚠️ 找不到 $PROXY_ENV，若計算節點需要外網請確保第 07 章 Proxy 已啟動。"
fi

# 測試連網能力
echo "測試外網連線能力..."
if curl -s -I --connect-timeout 5 https://www.google.com >/dev/null; then
    echo "✅ 計算節點外網連線成功！"
else
    echo "⚠️ 無法連通外網，請檢查登入節點 Tinyproxy 服務是否運行中。"
fi

# ------------------------------------------------------------------------------
# 2. 執行即時下載與分析流程
# ------------------------------------------------------------------------------
echo "正在執行分析管線..."
# python3 run_download_and_analyze.py --threads "${SLURM_CPUS_PER_TASK}"

echo "================================================================================"
echo "作業完成時間 : $(date)"
echo "================================================================================"
