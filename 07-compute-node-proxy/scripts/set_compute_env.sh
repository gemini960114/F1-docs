#!/usr/bin/env bash
# ==============================================================================
# set_compute_env.sh - 在 Compute Node (計算節點) 載入 Proxy 設定
# 用法: source set_compute_env.sh [LOGIN_NODE_IP] [PORT]
# ==============================================================================

# 預設 Login Node 的 InfiniBand 內網 IP 與連接埠
PROXY_HOST="${1:-10.200.160.1}"
PROXY_PORT="${2:-8888}"
AUTH_FILE="${HOME}/.proxy_auth"

if [ ! -f "${AUTH_FILE}" ]; then
    echo "⚠️ 警告: 找不到 ${AUTH_FILE}。若 Proxy 有啟用認證，請先建立此檔案！"
    export http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export HTTP_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
    export HTTPS_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
else
    AUTH_INFO="$(cat "${AUTH_FILE}" | tr -d '\r\n')"
    export http_proxy="http://${AUTH_INFO}@${PROXY_HOST}:${PROXY_PORT}"
    export https_proxy="http://${AUTH_INFO}@${PROXY_HOST}:${PROXY_PORT}"
    export HTTP_PROXY="http://${AUTH_INFO}@${PROXY_HOST}:${PROXY_PORT}"
    export HTTPS_PROXY="http://${AUTH_INFO}@${PROXY_HOST}:${PROXY_PORT}"
fi

# 避免內網通訊 (如 node 間 MPI、local communication) 走 Proxy
export no_proxy="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,*.nchc.org.tw"
export NO_PROXY="${no_proxy}"

echo "✅ 計算節點 Proxy 環境變數已設定完畢！"
echo "   http_proxy  = ${http_proxy}"
echo "   https_proxy = ${https_proxy}"
echo "   no_proxy    = ${no_proxy}"
echo "   💡 提醒: 請確認登入節點已啟動 Proxy (執行 bash ~/hpc-tutorial/07-compute-node-proxy/scripts/start.sh)"
