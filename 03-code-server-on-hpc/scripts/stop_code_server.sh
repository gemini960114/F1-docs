#!/usr/bin/env bash
# ==============================================================================
# stop_code_server.sh - 停止 Login Node 上的 Code-Server 背景服務
# ==============================================================================
set -euo pipefail

SESSION_NAME="code-server"

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    echo "==> 正在關閉 tmux 工作階段: ${SESSION_NAME}..."
    tmux kill-session -t "${SESSION_NAME}"
    rm -f "${HOME}/.code-server-url.txt"
    echo "✅ Code-Server 服務已成功停止！"
else
    echo "ℹ️ 目前沒有運行中的 '${SESSION_NAME}' tmux 服務。"
fi
