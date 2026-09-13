#!/usr/bin/env bash
# ==============================================================================
# start.sh - 在 Login Node 安全啟動 HTTP Proxy (背景 tmux 常駐)
# ==============================================================================
set -euo pipefail

SESSION_NAME="http-proxy"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="${SCRIPT_DIR}/start_proxy.py"
PORT="${1:-8888}"
AUTH_FILE="${HOME}/.proxy_auth"

# 1. 檢查虛擬環境是否存在
if [ ! -d "${HOME}/.venv-proxy" ]; then
    echo "未偵測到 Proxy 虛擬環境，正在自動執行 setup_env.sh..."
    bash "${SCRIPT_DIR}/setup_env.sh"
fi

# 2. 檢查或生成個人密碼檔 (~/.proxy_auth)
if [ ! -f "${AUTH_FILE}" ]; then
    DEFAULT_USER="$(whoami)"
    # 生成 12 碼隨機密碼
    RANDOM_PASS="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12 || true)"
    echo "${DEFAULT_USER}:${RANDOM_PASS}" > "${AUTH_FILE}"
    chmod 600 "${AUTH_FILE}"
    echo "⚠️ 尚未偵測到密碼檔，已為您自動生成預設密碼檔: ${AUTH_FILE}"
    echo "   預設帳密為 -> ${DEFAULT_USER}:${RANDOM_PASS}"
    echo "   (若欲修改請自行編輯 ${AUTH_FILE})"
else
    # 確保權限為 600 (只有自己能讀寫)
    chmod 600 "${AUTH_FILE}"
fi

# 3. 檢查 tmux session 是否已經存在
if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    echo "⚠️ tmux session '${SESSION_NAME}' 已經在運行中！"
    echo "若要重啟，請先執行: bash ${SCRIPT_DIR}/stop.sh"
    exit 0
fi

# 4. 取得本機叢集內網 IP
IB_IP="$(ip -4 addr show ib0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)"
ETH_IP="$(ip -4 addr show enp3s0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)"
HOST_IP="${IB_IP:-${ETH_IP:-127.0.0.1}}"

# 5. 啟動 tmux 背景常駐 session
echo "==> 正在啟動 Proxy 服務 (Port: ${PORT})..."
tmux new-session -d -s "${SESSION_NAME}" "'${LAUNCHER}' --port ${PORT}"
sleep 1.5

# 6. 驗證服務是否成功啟動
if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    AUTH_INFO="$(cat "${AUTH_FILE}")"
    echo "========================================================"
    echo "🎉 HTTP Proxy 成功於背景 (tmux) 啟動！"
    echo "========================================================"
    echo "登入節點內網 IP : ${HOST_IP}"
    echo "服務連接埠 (Port): ${PORT}"
    echo "認證帳號密碼    : ${AUTH_INFO}"
    echo "進程資安防護    : ✅ 已隱藏，ps 指令無法窺探密碼"
    echo "--------------------------------------------------------"
    echo "👉 在計算節點 (Compute Node) 請執行以下設定："
    echo ""
    echo "export http_proxy=\"http://${AUTH_INFO}@${HOST_IP}:${PORT}\""
    echo "export https_proxy=\"http://${AUTH_INFO}@${HOST_IP}:${PORT}\""
    echo ""
    echo "測試連線: curl -I https://huggingface.co"
    echo "========================================================"
else
    echo "❌ 啟動失敗，請檢查日誌或手動執行測試。"
    exit 1
fi
