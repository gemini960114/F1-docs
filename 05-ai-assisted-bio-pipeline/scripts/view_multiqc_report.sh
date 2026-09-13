#!/usr/bin/env bash
# ==============================================================================
# view_multiqc_report.sh - 透過第 2 章的反向代理，在瀏覽器即時預覽 MultiQC 報告
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${SCRIPT_DIR}/../demo_data/multiqc_out"
REPORT_FILE="${REPORT_DIR}/multiqc_report.html"

if [ ! -f "${REPORT_FILE}" ]; then
    echo "❌ 找不到 ${REPORT_FILE}，請先執行 run_fastqc_multiqc.sh 產生報告！"
    exit 1
fi

PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
HOSTNAME=$(hostname -s)
SESSION="svc-multiqc-report"

if tmux has-session -t "${SESSION}" 2>/dev/null; then
    tmux kill-session -t "${SESSION}"
fi

# 啟動 Python HTTP 伺服器提供 HTML 預覽
tmux new-session -d -s "${SESSION}" "cd '${REPORT_DIR}' && python3 -m http.server ${PORT} --bind 0.0.0.0"

OOD_URL="https://f1-stn01.nchc.org.tw/rnode/${HOSTNAME}/${PORT}/multiqc_report.html"

echo "========================================================"
echo "📊 MultiQC HTML 報告預覽服務已啟動！"
echo "========================================================"
echo "主機節點 : ${HOSTNAME}"
echo "分配埠號 : ${PORT}"
echo "--------------------------------------------------------"
echo "👉 請在瀏覽器直接點擊此 OOD 反向代理網址檢視互動式報告："
echo "   ${OOD_URL}"
echo "--------------------------------------------------------"
echo "關閉預覽服務指令: tmux kill-session -t ${SESSION}"
echo "========================================================"
