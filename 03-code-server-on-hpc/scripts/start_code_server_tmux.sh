#!/usr/bin/env bash
# ==============================================================================
# start_code_server_tmux.sh - 在 Login Node 安全啟動 Code-Server (tmux 背景常駐版)
# ==============================================================================
set -euo pipefail

SESSION_NAME="code-server"
PASSWORD_FILE="${HOME}/.code-server-password"
URL_FILE="${HOME}/.code-server-url.txt"

# 1. 檢查是否已有正在運行的 tmux session
if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    echo "⚠️ tmux 工作階段 '${SESSION_NAME}' 已經在運行中！"
    echo "--------------------------------------------------------"
    if [ -f "${URL_FILE}" ]; then
        echo "目前運行的存取網址: $(cat "${URL_FILE}")"
    fi
    echo "進入即時視窗 : tmux attach -t ${SESSION_NAME}"
    echo "停止此服務   : tmux kill-session -t ${SESSION_NAME}"
    echo "--------------------------------------------------------"
    exit 0
fi

# 2. 尋找可用之 code-server 執行檔
if [ -x "${HOME}/.local/bin/code-server" ]; then
    CODE_SERVER="${HOME}/.local/bin/code-server"
elif command -v code-server &>/dev/null; then
    CODE_SERVER="$(command -v code-server)"
else
    # 嘗試由系統模組載入
    if command -v module &>/dev/null; then
        module load tools/code-server 2>/dev/null || true
    fi
    if command -v code-server &>/dev/null; then
        CODE_SERVER="$(command -v code-server)"
    else
        echo "❌ 錯誤: 找不到 code-server 執行檔！"
        echo "請先安裝 code-server，或確認 ~/.local/bin/code-server 是否存在。"
        exit 1
    fi
fi

# 3. 檢查或生成個人密碼檔
if [ ! -f "${PASSWORD_FILE}" ]; then
    RANDOM_PASS="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 14 || true)"
    echo "${RANDOM_PASS}" > "${PASSWORD_FILE}"
    chmod 600 "${PASSWORD_FILE}"
    echo "⚠️ 尚未偵測到密碼檔，已自動生成安全密碼於: ${PASSWORD_FILE}"
else
    chmod 600 "${PASSWORD_FILE}"
fi
PASSWORD="$(cat "${PASSWORD_FILE}" | tr -d '\r\n')"

# 4. 動態取得未被佔用的連接埠
PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
MY_HOSTNAME=$(hostname -s)

# 5. 拼裝國網中心 Open OnDemand (OOD) 反向代理網址
OOD_URL="https://f1-stn01.nchc.org.tw/rnode/${MY_HOSTNAME}/${PORT}/?folder=${HOME}"

# 6. 組裝啟動指令 (綁定 0.0.0.0 確保所有介面皆可連通)
CMD="export PASSWORD='${PASSWORD}' && '${CODE_SERVER}' --bind-addr '0.0.0.0:${PORT}' --auth password --cert false '${HOME}'"

# 7. 在 tmux 背景中建立 session 並執行
tmux new-session -d -s "${SESSION_NAME}" "${CMD}"
sleep 1.5

# 8. 驗證啟動狀態
if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    echo "${OOD_URL}" > "${URL_FILE}"
    echo "========================================================"
    echo "🎉 Code-Server 已成功於背景 (tmux) 啟動！"
    echo "========================================================"
    echo "登入節點主機   : ${MY_HOSTNAME}"
    echo "服務連接埠     : ${PORT}"
    echo "登入密碼       : (已由 ${PASSWORD_FILE} 載入)"
    echo "code-server 版本: $("${CODE_SERVER}" --version | head -n 1)"
    echo "--------------------------------------------------------"
    echo "🌐 國網中心 OOD 存取網址 (請於瀏覽器開啟):"
    echo "👉 ${OOD_URL}"
    echo "--------------------------------------------------------"
    echo "🔍 常用管理指令:"
    echo "   查看即時日誌 : tmux attach -t ${SESSION_NAME}  (離開按 Ctrl+B 後按 D)"
    echo "   關閉此服務   : tmux kill-session -t ${SESSION_NAME}"
    echo "========================================================"
else
    echo "❌ 啟動失敗，請檢查 tmux 日誌或手動測試執行。"
    exit 1
fi
