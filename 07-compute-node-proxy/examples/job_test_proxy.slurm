#!/usr/bin/env bash
#SBATCH --job-name=test_proxy
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:10:00
#SBATCH --output=test_proxy_%j.out
#SBATCH --error=test_proxy_%j.err

# ==============================================================================
# job_test_proxy.slurm - Slurm 任務自動載入 Proxy 測試範例
# 提交方式: sbatch job_test_proxy.slurm
# ==============================================================================

echo "=========================================================="
echo "作業啟動時間: $(date)"
echo "執行節點    : $(hostname)"
echo "作業 ID     : ${SLURM_JOB_ID}"
echo "=========================================================="

# 1. 取得當前專案腳本目錄
SCRIPT_DIR="${SLURM_SUBMIT_DIR}/../scripts"

# 2. 載入 Proxy 環境變數 (會自動讀取 ~/.proxy_auth)
if [ -f "${SCRIPT_DIR}/set_compute_env.sh" ]; then
    echo "==> 載入 Proxy 設定檔..."
    source "${SCRIPT_DIR}/set_compute_env.sh" "10.200.160.1" "8888"
else
    echo "❌ 找不到 set_compute_env.sh，請確認路徑！"
    exit 1
fi

echo ""
echo "==> [測試 1] 透過 curl 測試連線 Hugging Face & GitHub..."
bash "${SLURM_SUBMIT_DIR}/test_connection.sh"

echo ""
echo "==> [測試 2] 透過 Python 存取 Hugging Face API..."
python3 "${SLURM_SUBMIT_DIR}/download_hf_model.py"

echo ""
echo "=========================================================="
echo "作業測試完成時間: $(date)"
echo "=========================================================="
