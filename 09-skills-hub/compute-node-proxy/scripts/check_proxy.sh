#!/usr/bin/env bash
# ==============================================================================
# check_proxy.sh - 登入節點 Proxy 運行狀態與網路環境診斷腳本
# 用法: bash check_proxy.sh [PORT]
# ==============================================================================
set -euo pipefail

PORT="${1:-8888}"
SESSION_NAME="http-proxy"
AUTH_FILE="${HOME}/.proxy_auth"

echo "========================================================"
echo "🔍 國網創進一號 (f1) 計算節點 Proxy 連線診斷"
echo "========================================================"

# 1. 檢查 InfiniBand / 乙太網路內網 IP
IB_IP="$(ip -4 addr show ib0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)"
ETH_IP="$(ip -4 addr show enp3s0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)"
LOGIN_IP="${IB_IP:-${ETH_IP:-127.0.0.1}}"

echo "📡 登入節點內網 IP: ${LOGIN_IP}"
if [ -n "${IB_IP}" ]; then
    echo "   (已偵測到 InfiniBand ib0 介面: ${IB_IP}，優先推薦)"
fi

# 2. 檢查安全密碼檔
if [ -f "${AUTH_FILE}" ]; then
    PERM=$(stat -c "%a" "${AUTH_FILE}" 2>/dev/null || stat -f "%Lp" "${AUTH_FILE}" 2>/dev/null || echo "unknown")
    if [ "${PERM}" = "600" ]; then
        echo "🔐 認證密碼檔: ✅ 存在 (${AUTH_FILE})，權限正常 (600)"
    else
        echo "⚠️ 認證密碼檔: 存在但權限過於開放 (${PERM})，強烈建議執行: chmod 600 ${AUTH_FILE}"
    fi
else
    echo "❌ 認證密碼檔: 尚未建立 (${AUTH_FILE})"
fi

# 3. 檢查 Proxy 背景進程 (tmux / port)
IS_TMUX_RUNNING=0
if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    IS_TMUX_RUNNING=1
fi

IS_PORT_LISTENING=0
if command -v ss >/dev/null 2>&1; then
    if ss -ltn 2>/dev/null | grep -q ":${PORT}\b"; then
        IS_PORT_LISTENING=1
    fi
elif command -v netstat >/dev/null 2>&1; then
    if netstat -ltn 2>/dev/null | grep -q ":${PORT}\b"; then
        IS_PORT_LISTENING=1
    fi
fi

echo "--------------------------------------------------------"
if [ ${IS_TMUX_RUNNING} -eq 1 ] || [ ${IS_PORT_LISTENING} -eq 1 ]; then
    echo "🚀 Proxy 服務狀態: 🟢 運行中 (Listening on :${PORT})"
    if [ ${IS_TMUX_RUNNING} -eq 1 ]; then
        echo "   tmux 會話名: ${SESSION_NAME}"
    fi

    # 4. 本地迴路連線測試
    if [ -f "${AUTH_FILE}" ]; then
        AUTH_INFO="$(cat "${AUTH_FILE}" | tr -d '\r\n')"
        echo "🧪 正在進行外網連線穿透測試 (https://huggingface.co)..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -I --connect-timeout 3 -x "http://${AUTH_INFO}@127.0.0.1:${PORT}" https://huggingface.co || echo "000")
        if [ "${HTTP_CODE}" = "200" ] || [ "${HTTP_CODE}" = "301" ] || [ "${HTTP_CODE}" = "302" ]; then
            echo "   ✅ 外網連線穿透測試成功！(HTTP Status: ${HTTP_CODE})"
        else
            echo "   ⚠️ 連線測試未回傳 200 (HTTP Status: ${HTTP_CODE})，請檢查外網連線或認證帳密。"
        fi
    fi

    echo "--------------------------------------------------------"
    echo "💡 在 Slurm 腳本或計算節點中使用此 Proxy："
    echo "   source ~/hpc-tutorial/07-compute-node-proxy/scripts/set_compute_env.sh"
    echo "   或手動設定:"
    if [ -f "${AUTH_FILE}" ]; then
        echo "   export http_proxy=\"http://\$(cat ~/.proxy_auth)@${LOGIN_IP}:${PORT}\""
        echo "   export https_proxy=\"http://\$(cat ~/.proxy_auth)@${LOGIN_IP}:${PORT}\""
    else
        echo "   export http_proxy=\"http://${LOGIN_IP}:${PORT}\""
        echo "   export https_proxy=\"http://${LOGIN_IP}:${PORT}\""
    fi
else
    echo "🛑 Proxy 服務狀態: 🔴 尚未啟動"
    echo "--------------------------------------------------------"
    echo "💡 若計算節點作業需要連網，請先在登入節點執行以下指令啟動 Proxy："
    echo "   bash ~/hpc-tutorial/07-compute-node-proxy/scripts/start.sh"
fi
echo "========================================================"
