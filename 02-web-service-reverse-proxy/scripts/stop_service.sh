#!/usr/bin/env bash
# ==============================================================================
# stop_service.sh - 停止特定網頁服務或列出目前運行的網頁服務
# 用法:
#   bash stop_service.sh [APP_NAME]
# ==============================================================================
set -euo pipefail

APP_NAME="${1:-}"

if [ -z "$APP_NAME" ]; then
    echo "========================================================"
    echo "目前以 'svc-' 開頭的網頁服務列表 (tmux sessions):"
    echo "========================================================"
    tmux ls 2>/dev/null | grep "^svc-" || echo "（目前沒有運作中的 svc-* 網頁服務）"
    echo "--------------------------------------------------------"
    echo "用法提示: bash stop_service.sh <服務名稱>"
    echo "例如:     bash stop_service.sh my-web-app"
    exit 0
fi

SESSION="svc-${APP_NAME}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "==> 正在停止服務: ${SESSION}..."
    tmux kill-session -t "$SESSION"
    echo "✅ 服務 '${SESSION}' 已成功停止！"
else
    echo "⚠️ 找不到名為 '${SESSION}' 的服務。"
fi
