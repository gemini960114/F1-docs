#!/usr/bin/env bash
# ==============================================================================
# install_vscode_extensions.sh - 一鍵安裝 Code-Server 必備開發與 AI 擴充套件
# ==============================================================================
set -euo pipefail

# 1. 尋找 code-server 執行檔
if [ -x "${HOME}/.local/bin/code-server" ]; then
    CODE_SERVER="${HOME}/.local/bin/code-server"
elif command -v code-server &>/dev/null; then
    CODE_SERVER="$(command -v code-server)"
else
    echo "❌ 錯誤: 找不到 code-server，請先確認 ~/.local/bin/code-server 是否存在！"
    exit 1
fi

echo "========================================================"
echo "🚀 開始為 Code-Server 安裝核心與 AI 擴充套件..."
echo "使用執行檔: ${CODE_SERVER}"
echo "========================================================"

EXTENSIONS=(
    # --- Python & Jupyter 互動式開發套件 ---
    "ms-toolsai.jupyter"                  # Jupyter 核心
    "ms-toolsai.jupyter-keymap"           # Jupyter 快捷鍵
    "ms-toolsai.jupyter-renderers"        # 互動式圖表渲染器
    "ms-python.python"                    # Python 核心擴充
    "ms-python.debugpy"                   # Python 除錯器

    # --- AI 程式碼輔助套件 ---
    "anthropic.claude-code"               # Claude Code
    "openai.chatgpt"                      # ChatGPT 官方擴充
    "zoocodeorganization.zoo-code"        # Zoo Code (多模型代碼輔助)
    "google.google-antigravity"           # Antigravity IDE 核心
)

for ext in "${EXTENSIONS[@]}"; do
    echo "==> 正在安裝擴充套件: ${ext} ..."
    "${CODE_SERVER}" --install-extension "${ext}" --force || {
        echo "⚠️ 安裝 ${ext} 失敗或套件暫時不可用，繼續安裝其他套件..."
    }
done

echo "========================================================"
echo "✅ 擴充套件安裝流程完成！"
echo "目前已安裝的擴充套件清單:"
"${CODE_SERVER}" --list-extensions
echo "========================================================"
