#!/bin/bash
# ==============================================================================
# 創進一號 (Forerunner 1 / F1) 登入後快速健康檢查腳本
# 用途：確認目前登入節點狀態、計畫點數、儲存空間與外網連通性
# ==============================================================================

set -u

echo "=========================================================="
echo " 🚀 創進一號 (f1) 登入節點環境健檢報告 (Login Node Healthcheck)"
echo "=========================================================="

echo -e "\n[1] 節點與系統資訊："
echo "• 當前主機名稱 (Hostname) : $(hostname -f 2>/dev/null || hostname)"
echo "• 登入使用者 (User)        : $(whoami)"
echo "• 作業系統版本 (OS)        : $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"')"
echo "• CPU 核心數 (Cores)       : $(nproc) 核心"
echo "• 系統總記憶體 (Memory)    : $(free -h | awk '/^Mem:/{print $2}')"

echo -e "\n[2] 計畫與 SU 錢包餘額 (wallet)："
if command -v wallet &>/dev/null; then
    wallet || echo "⚠️ 查無計畫或 wallet 執行異常"
else
    echo "⚠️ 系統未安裝 wallet 指令，請向管理者確認計畫設定。"
fi

echo -e "\n[3] 檔案儲存空間路徑確認："
echo "• 家目錄 (\$HOME)           : $HOME (檔案系統剩餘: $(df -h "$HOME" | awk 'NR==2 {print $4}'))"
echo "  ↳ ⚠️ 提醒: 上述為叢集總容量；個人/計畫配額請依 iService 申請為準 (GOV 類預設 100GB)"
if [ -d "/work1/$USER" ]; then
    echo "• 高速工作目錄 (/work1)   : /work1/$USER (高速運算主空間，GOV 預設 100GB，無備份)"
fi
if [ -d "/project" ]; then
    echo "• 計畫共用目錄 (/project) : 已掛載 (若計畫有額外申請共用空間請洽詢承辦)"
fi

echo -e "\n[4] 登入節點外網連通性測試："
if curl -s -I --connect-timeout 5 https://huggingface.co | grep -q -E "HTTP/.* [23]00"; then
    echo "✅ 外網連線正常 (Hugging Face 連通)"
else
    echo "⚠️ 外網連線逾時，請檢查防火牆或 DNS"
fi

if curl -s -I --connect-timeout 5 https://github.com | grep -q -E "HTTP/.* [23]00"; then
    echo "✅ 外網連線正常 (GitHub 連通)"
else
    echo "⚠️ GitHub 連線逾時"
fi

echo -e "\n=========================================================="
echo "🎉 健檢完成！登入節點運作正常，您可以接續進行下一章課程。"
echo "=========================================================="
