#!/usr/bin/env bash
# ==============================================================================
# test_compute_connection.sh - 在計算節點測試 Proxy 對外連網能力 (含防呆逾時)
# 用法: bash test_compute_connection.sh [TEST_URL]
# ==============================================================================
set -euo pipefail

TEST_URL="${1:-https://huggingface.co}"
TIMEOUT=5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 正在驗證計算節點外網代理連線..."
echo "   測試目標: ${TEST_URL}"
echo "   http_proxy  = ${http_proxy:-未設定}"
echo "   https_proxy = ${https_proxy:-未設定}"

if [ -z "${http_proxy:-}" ] && [ -z "${https_proxy:-}" ]; then
    echo "❌ 錯誤: 未偵測到 http_proxy 或 https_proxy 環境變數！"
    echo "💡 請先執行: source ${SCRIPT_DIR}/set_compute_env.sh"
    exit 1
fi

if HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -I --connect-timeout "${TIMEOUT}" "${TEST_URL}"); then
    if [ "${HTTP_CODE}" = "200" ] || [ "${HTTP_CODE}" = "301" ] || [ "${HTTP_CODE}" = "302" ]; then
        echo "✅ 外網連線驗證成功！(HTTP 狀態碼: ${HTTP_CODE})"
        exit 0
    else
        echo "⚠️ 連線已建立，但伺服器回傳非 200/30x 狀態碼 (HTTP 狀態碼: ${HTTP_CODE})"
        exit 0
    fi
else
    echo "❌ 連線失敗！計算節點無法透過 Proxy 連線至 ${TEST_URL} (逾時 ${TIMEOUT} 秒)。"
    echo "💡 請檢查："
    echo "   1. 登入節點上的 Proxy 是否仍在執行 (bash ${SCRIPT_DIR}/check_proxy.sh)"
    echo "   2. 密碼檔 ~/.proxy_auth 是否一致"
    echo "   3. 內網 IP 是否為 10.200.160.1 (ib0)"
    exit 1
fi
