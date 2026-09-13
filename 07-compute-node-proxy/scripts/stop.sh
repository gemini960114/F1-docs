#!/usr/bin/env bash
# ==============================================================================
# stop.sh - 停止 Login Node 上的 HTTP Proxy 服務
# ==============================================================================
set -euo pipefail

SESSION_NAME="http-proxy"

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    echo "==> 正在關閉 tmux session '${SESSION_NAME}'..."
    tmux kill-session -t "${SESSION_NAME}"
    echo "✅ HTTP Proxy 服務已安全關閉！"
else
    echo "ℹ️ 目前沒有運行中的 '${SESSION_NAME}' 服務。"
fi
