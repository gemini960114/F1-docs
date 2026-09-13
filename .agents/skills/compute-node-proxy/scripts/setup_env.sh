#!/usr/bin/env bash
# ==============================================================================
# setup_env.sh - 建立 Proxy 專屬 Python 虛擬環境
# ==============================================================================
set -euo pipefail

VENV_PATH="${HOME}/.venv-proxy"

echo "==> [1/3] 檢查 uv 套件管理工具..."
if ! command -v uv &>/dev/null; then
    if [ -f "${HOME}/.local/bin/uv" ]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    else
        echo "未找到 uv，正在為使用者安裝 uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
fi
echo "uv 版本: $(uv --version)"

echo "==> [2/3] 建立專屬虛擬環境於: ${VENV_PATH}..."
if [ ! -d "${VENV_PATH}" ]; then
    uv venv "${VENV_PATH}"
else
    echo "虛擬環境已存在，略過建立步驟。"
fi

echo "==> [3/3] 安裝高效輕量 proxy.py 套件..."
uv pip install --python "${VENV_PATH}/bin/python" proxy.py

echo "--------------------------------------------------------"
echo "✅ Proxy 環境安裝完成！"
echo "Python 路徑 : ${VENV_PATH}/bin/python"
echo "Proxy 版本  : $(${VENV_PATH}/bin/proxy --version)"
echo "--------------------------------------------------------"
