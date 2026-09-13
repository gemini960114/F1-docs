#!/bin/bash
# ==============================================================================
# 創進一號 (Taiwania 1 / f1) Environment Modules 實務操作示範腳本
# 用途：示範在登入節點如何查詢、載入、切換與重設模組環境
# ==============================================================================

set -e

echo "=========================================================="
echo " 🛠️ 創進一號 Environment Modules (ml/module) 操作示範"
echo "=========================================================="

# 1. 檢查 module 指令是否存在
if ! command -v module &>/dev/null; then
    echo "❌ 系統未載入 module 系統，請檢查 /etc/profile.d/modules.sh"
    exit 1
fi

echo -e "\n[1] 查看目前已載入的模組清單 (ml list)："
module list 2>&1 || true

echo -e "\n[2] 執行環境徹底重設 (module purge)："
echo ">> 執行: module purge"
module purge
echo "已清空所有已載入模組，確保環境純淨無污染。"

echo -e "\n[3] 示範階層式模組載入 (Hierarchical Loading)："
echo "國網官方規則：需先載入底層編譯器，再載入上層相依套件。"
echo ">> 執行: module load gcc"
if module load gcc 2>/dev/null; then
    echo "✅ GCC 編譯器模組載入成功！"
    gcc --version | head -n 1
else
    echo "⚠️ 載入預設 gcc 失敗，嘗試指定版本..."
fi

echo -e "\n[4] 檢查目前載入狀態 (ml)："
module list 2>&1

echo -e "\n[5] 模組搜尋技巧示範 (module spider)："
echo "欲尋找特定工具（如 python, cuda, openmpi），可使用 spider 指令："
echo "範例指令: module spider openmpi"

echo -e "\n=========================================================="
echo "🎉 示範完成！在撰寫 Slurm 排程腳本時，請牢記「第一行 module purge」黃金原則！"
echo "=========================================================="
