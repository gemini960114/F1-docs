#!/usr/bin/env bash
# ==============================================================================
# start_streamlit.sh - 啟動 Streamlit 服務並自動配置 baseUrlPath
# ==============================================================================
set -euo pipefail

SESSION="svc-streamlit"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
HOSTNAME=$(hostname -s)

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "⚠️ 服務 '$SESSION' 已經在運行中！"
    exit 0
fi

# 核心關鍵: --server.baseUrlPath 必須指定為 /rnode/${HOSTNAME}/${PORT}
CMD="streamlit run ${DIR}/streamlit_app.py \
  --server.address 0.0.0.0 \
  --server.port ${PORT} \
  --server.baseUrlPath /rnode/${HOSTNAME}/${PORT} \
  --server.enableCORS false \
  --server.enableXsrfProtection false"

tmux new-session -d -s "$SESSION" "$CMD"

OOD_URL="https://f1-stn01.nchc.org.tw/rnode/${HOSTNAME}/${PORT}/"
echo "========================================================"
echo "🎉 Streamlit 已成功啟動！"
echo "👉 存取網址: ${OOD_URL}"
echo "========================================================"
