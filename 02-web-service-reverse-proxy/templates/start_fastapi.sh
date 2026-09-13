#!/usr/bin/env bash
# ==============================================================================
# start_fastapi.sh - 啟動 FastAPI 服務並自動配置 root-path
# ==============================================================================
set -euo pipefail

SESSION="svc-fastapi"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
HOSTNAME=$(hostname -s)

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "⚠️ 服務 '$SESSION' 已經在運行中！"
    exit 0
fi

# 核心關鍵: 傳入 PORT 環境變數以及 uvicorn --root-path 與 --proxy-headers
CMD="export PORT=${PORT} && uvicorn fastapi_app:app \
  --app-dir ${DIR} \
  --host 0.0.0.0 \
  --port ${PORT} \
  --root-path /rnode/${HOSTNAME}/${PORT} \
  --proxy-headers"

tmux new-session -d -s "$SESSION" "$CMD"

OOD_URL="https://f1-stn01.nchc.org.tw/rnode/${HOSTNAME}/${PORT}/"
echo "========================================================"
echo "🎉 FastAPI 已成功啟動！"
echo "👉 根目錄網址: ${OOD_URL}"
echo "👉 Swagger 介面: ${OOD_URL}docs"
echo "========================================================"
