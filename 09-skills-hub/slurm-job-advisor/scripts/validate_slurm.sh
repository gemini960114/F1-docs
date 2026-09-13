#!/bin/bash
# ==============================================================================
# validate_slurm.sh: 驗證 Slurm 腳本之參數合理性與模擬排程預檢
# ==============================================================================
set -e

SLURM_FILE="$1"
if [ -z "$SLURM_FILE" ] || [ ! -f "$SLURM_FILE" ]; then
    echo "❌ 錯誤：請指定有效的 Slurm 腳本路徑。"
    echo "用法：$0 <your_job.slurm>"
    exit 1
fi

echo "================================================================================"
echo "🔍 正在靜態分析 Slurm 腳本：$SLURM_FILE"
echo "================================================================================"

# 1. 檢查 Account
ACCOUNT=$(grep -E "^#SBATCH\s+(-A|--account=)" "$SLURM_FILE" | head -n 1 | awk -F'=' '{print $2}' | awk '{print $1}' | tr -d ' ' || true)
if [ -z "$ACCOUNT" ]; then
    ACCOUNT=$(grep -E "^#SBATCH\s+-A\s+" "$SLURM_FILE" | head -n 1 | awk '{print $3}' || true)
fi

if [ -z "$ACCOUNT" ]; then
    echo "❌ [嚴重錯誤] 缺少計費計畫代號 (#SBATCH -A 或 #SBATCH --account)！"
    echo "   國網中心 Slurm 必須明確指定計畫代號，否則排程器會直接拋出錯誤。"
else
    echo "✅ 計畫代號 (Account): $ACCOUNT"
fi

# 2. 檢查 Partition
PARTITION=$(grep -E "^#SBATCH\s+(-p|--partition=)" "$SLURM_FILE" | head -n 1 | awk -F'=' '{print $2}' | awk '{print $1}' | tr -d ' ' || true)
if [ -z "$PARTITION" ]; then
    PARTITION=$(grep -E "^#SBATCH\s+-p\s+" "$SLURM_FILE" | head -n 1 | awk '{print $3}' || true)
fi

if [ -z "$PARTITION" ]; then
    echo "⚠️ [警告] 未指定佇列分區 (#SBATCH -p / --partition)，將使用叢集預設佇列。"
else
    echo "✅ 佇列分區 (Partition): $PARTITION"
    # 檢查非法分區
    if [[ "$PARTITION" =~ ^(vscode|jupyter|rstudio|desktop)$ ]]; then
        echo "❌ [嚴重錯誤] 分區 '$PARTITION' 限由 Open OnDemand (OOD) Web 介面派送！"
        echo "   在登入節點直接提交會遭遇 'allocation failure: Access/permission denied'。"
    elif [[ "$PARTITION" =~ ^(visual|visual-dev)$ ]]; then
        echo "❌ [嚴重錯誤] 分區 '$PARTITION' 為繪圖佇列，限從繪圖登入節點 (intgpn01~04) 派送！"
    elif [[ "$PARTITION" =~ ^arm ]]; then
        echo "❌ [嚴重錯誤] 分區 '$PARTITION' 為 ARM 佇列，限從 ARM 登入節點 (nlgn01~04) 派送！"
    fi
fi

# 3. 檢查核心數與節點數
NODES=$(grep -E "^#SBATCH\s+(-N|--nodes=)" "$SLURM_FILE" | head -n 1 | awk -F'=' '{print $2}' | awk '{print $1}' || echo "1")
CPUS=$(grep -E "^#SBATCH\s+(-c|--cpus-per-task=)" "$SLURM_FILE" | head -n 1 | awk -F'=' '{print $2}' | awk '{print $1}' || echo "1")
echo "✅ 申請資源規模: 節點數 = $NODES, 每個行程核心數 = $CPUS"

if [ "$NODES" -eq 1 ] && [ "$CPUS" -gt 112 ]; then
    echo "❌ [嚴重錯誤] 單節點核心數 $CPUS 超過實體上限 (112 核心)！"
    echo "   若需要超過 112 核心，請改用跨節點 MPI 平行架構與 ct448~ct8k 佇列。"
fi

# 4. 檢查不合理配置 (如 100 cores 配 1G ram)
MEM_SETTING=$(grep -E "^#SBATCH\s+--mem" "$SLURM_FILE" | head -n 1 || true)
if [ -n "$MEM_SETTING" ]; then
    echo "ℹ️ 記憶體設定: $MEM_SETTING"
    if [ "$CPUS" -ge 64 ] && [[ "$MEM_SETTING" =~ --mem=[1-4]G ]]; then
        echo "⚠️ [不合理配置警告] 申請高達 $CPUS 核心卻僅指定極小記憶體 ($MEM_SETTING)！"
        echo "   在標準薄節點 (ct112) 上每核心具備 4.3 GB RAM，此設定極度浪費 CPU 算力且易造成資源鎖定失衡。"
    fi
fi

# 5. 檢查日誌目錄依賴
LOG_OUT=$(grep -E "^#SBATCH\s+(-o|--output=)" "$SLURM_FILE" | head -n 1 | awk -F'=' '{print $2}' | awk '{print $1}' || true)
if [[ "$LOG_OUT" == */* ]]; then
    DIR_PART=$(dirname "$LOG_OUT")
    if [ ! -d "$DIR_PART" ]; then
        echo "❌ [地雷警告] 日誌路徑 '$LOG_OUT' 的目錄 '$DIR_PART' 不存在！"
        echo "   Slurm 不會自動建立目錄，作業將立即崩潰 (No such file or directory)。"
        echo "   建議改用萬用格式: #SBATCH --output=%x-%j.out"
    fi
fi

echo ""
echo "================================================================================"
echo "🚀 6. 執行排程器免扣點預檢 (sbatch --test-only)"
echo "================================================================================"
TEST_OUTPUT=$(sbatch --test-only "$SLURM_FILE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "🎉 [驗證通過] Slurm 排程器確認語法與計畫額度有效！"
    echo "$TEST_OUTPUT"
    echo ""
    echo "💡 您隨時可以使用以下指令正式提交作業："
    echo "   sbatch $SLURM_FILE"
else
    echo "❌ [驗證失敗] 排程器拒絕接受此作業，原因如下："
    echo "$TEST_OUTPUT"
fi
echo "================================================================================"
