#!/usr/bin/env bash
#SBATCH --job-name=proxy_workload
#SBATCH --account=YOUR_PROJECT_ID          # 請由 `wallet` 查詢並填入 (如 GOV114022)
#SBATCH --partition=ct112                  # 薄節點佇列 (4.3 GB RAM/Core) 或 development (除錯)
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4                  # 依需求配置核心數 (4 核約 17.2 GB RAM)
#SBATCH --time=01:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# ==============================================================================
# 國網創進一號 (f1) 計算節點安全 Proxy 作業範本
# 特點：
# 1. 自動從安全檔案 ~/.proxy_auth 載入認證，杜絕 ps aux 密碼洩漏
# 2. 透過 InfiniBand 內網 (10.200.160.1:8888) 穿透至登入節點外網
# 3. 具備 5 秒快速預檢機制：外網斷線立即退出，絕不白耗算力點數 (SU)
# ==============================================================================

set -euo pipefail

echo "========================================================"
echo "🕒 作業開始時間: $(date)"
echo "🖥️ 執行節點: $(hostname)"
echo "========================================================"

# ------------------------------------------------------------------------------
# 步驟 1：載入 Proxy 環境變數 (優先讀取 Skill 內建腳本)
# ------------------------------------------------------------------------------
# 提示：此路徑在 AI 產生 Slurm 腳本時，應動態替換為該次 skill 實際安裝目錄下的 scripts/set_compute_env.sh
PROXY_SCRIPT="${PROXY_SCRIPT:-$HOME/.agents/skills/compute-node-proxy/scripts/set_compute_env.sh}"

if [ -f "$PROXY_SCRIPT" ]; then
    echo "==> 正在載入 Proxy 環境變數 (${PROXY_SCRIPT})..."
    source "$PROXY_SCRIPT"
else
    echo "==> 採用備援環境變數配置 (注意：備援模式僅設定變數，登入節點仍須有人工啟動的 Proxy 服務)..."
    LOGIN_IP="10.200.160.1"
    PORT="8888"
    AUTH_FILE="$HOME/.proxy_auth"
    
    if [ -f "$AUTH_FILE" ]; then
        AUTH_INFO="$(cat "$AUTH_FILE" | tr -d '\r\n')"
        export http_proxy="http://${AUTH_INFO}@${LOGIN_IP}:${PORT}"
        export https_proxy="http://${AUTH_INFO}@${LOGIN_IP}:${PORT}"
    else
        export http_proxy="http://${LOGIN_IP}:${PORT}"
        export https_proxy="http://${LOGIN_IP}:${PORT}"
    fi
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export no_proxy="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12"
    export NO_PROXY="$no_proxy"
fi

# ------------------------------------------------------------------------------
# 步驟 2：外網連線防呆預檢 (Fail-Fast: 逾時 5 秒即退出)
# ------------------------------------------------------------------------------
CHECK_URL="https://huggingface.co"
echo "==> 正在進行外網連線預檢 (${CHECK_URL})..."

if ! curl -s -I --connect-timeout 5 "$CHECK_URL" > /dev/null; then
    echo "❌ 嚴重錯誤：計算節點無法透過 Proxy 連線至外網！"
    echo "💡 失敗原因排查："
    echo "   1. 請確認登入節點 (ilgn01) 是否已啟動 Proxy："
    echo "      bash <此 skill 的 scripts 目錄>/start.sh"
    echo "   2. 請確認登入節點上的 tmux session 'http-proxy' 仍在運行。"
    echo "   3. 請確認 ~/.proxy_auth 密碼未被重設或誤刪。"
    echo "🛑 終止作業以避免浪費計畫點數。"
    exit 1
fi
echo "✅ 外網 Proxy 通道連線正常！"

# ------------------------------------------------------------------------------
# 步驟 3：執行使用者需要連網的計算任務
# ------------------------------------------------------------------------------
echo "==> 開始執行主運算任務..."

# 範例 A: 下載模型或套件 (依實際需求替換)
# python -c "import urllib.request; print(urllib.request.urlopen('https://api.github.com').getcode())"

# 範例 B: 執行訓練並回傳指標至 Weights & Biases (wandb)
# python train.py --report_to wandb

echo "========================================================"
echo "🎉 作業順利完成時間: $(date)"
echo "========================================================"
