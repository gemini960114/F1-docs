#!/usr/bin/env bash
# ==============================================================================
# password_setup.sh - 設定或重新生成 Code-Server 安全密碼
# 用法:
#   bash password_setup.sh [自訂密碼]
# ==============================================================================
set -euo pipefail

PASSWORD_FILE="${HOME}/.code-server-password"

if [ -n "${1:-}" ]; then
    NEW_PASS="$1"
else
    # 自動生成 14 碼安全隨機密碼
    NEW_PASS="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 14 || true)"
fi

echo "${NEW_PASS}" > "${PASSWORD_FILE}"
chmod 600 "${PASSWORD_FILE}"

echo "========================================================"
echo "✅ Code-Server 密碼已設定成功！"
echo "檔案路徑: ${PASSWORD_FILE}"
echo "檔案權限: -rw------- (僅本人可讀寫，防止其他人窺探)"
echo "密碼內容: ${NEW_PASS}"
echo "========================================================"
