#!/usr/bin/env bash
# ==============================================================================
# universal_start.sh - 萬用網頁服務背景啟動腳本 (HPC / 反向代理專用)
# 用法:
#   bash universal_start.sh <服務名稱> "<啟動指令>"
# 範例:
#   bash universal_start.sh my-web "python3 -m http.server {PORT} --bind 0.0.0.0"
# ==============================================================================
set -euo pipefail

APP_NAME="${1:-my-web-app}"
if [ -z "${2:-}" ]; then
    USER_CMD="python3 -m http.server {PORT} --bind 0.0.0.0"
else
    USER_CMD="$2"
fi
SESSION="svc-${APP_NAME}"
DIR="$(pwd)"

# 1. 取得保證閒置的 Port 與節點主機名稱
PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
HOSTNAME=$(hostname -s)

# 2. 將指令中的 {PORT} 與 {HOSTNAME} 佔位符替換
CMD="${USER_CMD//\{PORT\}/$PORT}"
CMD="${CMD//\{HOSTNAME\}/$HOSTNAME}"

# 3. 檢查 tmux session 是否已存在
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "⚠️ 服務 '$SESSION' 已經在運行中！"
    echo "請先關閉再啟動: tmux kill-session -t '$SESSION'"
    exit 0
fi

# 4. 在 tmux 背景中啟動服務
tmux new-session -d -s "$SESSION" "cd '$DIR' && $CMD"
sleep 1.5

# 5. 輸出存取網址
OOD_URL="https://f1-stn01.nchc.org.tw/rnode/${HOSTNAME}/${PORT}/"

echo "========================================================"
echo "🎉 網頁服務已成功於背景啟動！"
echo "========================================================"
echo "服務名稱      : ${APP_NAME}"
echo "tmux 會話名稱 : ${SESSION}"
echo "主機節點      : ${HOSTNAME}"
echo "分配連接埠    : ${PORT}"
echo "執行指令      : ${CMD}"
echo "--------------------------------------------------------"
echo "🌐 國網中心 OOD 外部存取網址 (結尾斜線不可省略):"
echo "👉 ${OOD_URL}"
echo "--------------------------------------------------------"
echo "🔍 常用管理指令:"
echo "   查看即時日誌: tmux attach -t ${SESSION}  (離開按 Ctrl+B 後按 D)"
echo "   關閉此服務  : tmux kill-session -t ${SESSION}"
echo "========================================================"

# 將網址存成文字檔供日後查閱
echo "${OOD_URL}" > "$DIR/service-url-${APP_NAME}.txt"
