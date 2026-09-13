#!/bin/bash
# ==============================================================================
# 創進一號 (Taiwania 1 / f1) 極速 Python 套件管理工具 uv 實務操作示範
# 用途：示範如何使用 uv 在高速工作目錄 (/work1) 秒級建立虛擬環境與安裝套件
# ==============================================================================

set -e

echo "=========================================================="
echo " ⚡ 創進一號 Python 套件管理利器：uv 實務示範"
echo "=========================================================="

# 1. 確保 uv 可用
UV_BIN="${HOME}/.local/bin/uv"
if ! command -v uv &>/dev/null && [ ! -x "${UV_BIN}" ]; then
    echo ">> 安裝 uv 至 ~/.local/bin..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="${HOME}/.local/bin:${PATH}"
fi

if command -v uv &>/dev/null; then
    UV_CMD="uv"
else
    UV_CMD="${UV_BIN}"
fi

echo "• uv 版本: $("${UV_CMD}" --version)"

# 2. 設定最佳實踐：將快取目錄指向大容量工作區 (/work1) 避免灌爆 $HOME
WORK_DIR="/work1/${USER}"
if [ ! -d "${WORK_DIR}" ]; then
    WORK_DIR="${HOME}/scratch"
    mkdir -p "${WORK_DIR}"
fi

TARGET_VENV="${WORK_DIR}/test_uv_env"
export UV_CACHE_DIR="${WORK_DIR}/.uv_cache"

echo -e "\n[步驟 1] 在高速工作區建立虛擬環境 (${TARGET_VENV})..."
rm -rf "${TARGET_VENV}"
"${UV_CMD}" venv "${TARGET_VENV}"

echo -e "\n[步驟 2] 透過 uv pip 秒級安裝示範套件 (requests, rich)..."
"${UV_CMD}" pip install --python "${TARGET_VENV}/bin/python" requests rich

echo -e "\n[步驟 3] 驗證虛擬環境運作與 Python 版本..."
"${TARGET_VENV}/bin/python" -c "import requests, rich; print('✅ 模組載入成功！Requests 版本:', requests.__version__)"

echo -e "\n=========================================================="
echo "🎉 示範成功！"
echo "💡 提示：日常使用時只需：source ${TARGET_VENV}/bin/activate 即可啟動環境！"
echo "=========================================================="
