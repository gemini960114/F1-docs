#!/bin/bash
# ==============================================================================
# check_slurm_env.sh: 檢查國網中心 (f1) Slurm 佇列狀態與錢包 (wallet) 計畫餘額
# ==============================================================================
set -e

echo "================================================================================"
echo "💳 1. 計畫錢包 (wallet) 可用計畫代號與 SU 點數餘額"
echo "================================================================================"
if [ -f /etc/profile.d/wallet_func.sh ]; then
    # shellcheck source=/dev/null
    source /etc/profile.d/wallet_func.sh
    wallet
else
    echo "⚠️ 未找到 /etc/profile.d/wallet_func.sh，請確認是否在國網登入節點。"
fi

echo ""
echo "================================================================================"
echo "🖥️ 2. 登入節點 (ilgn01) 可直接派送之佇列即時資源 (sinfo)"
echo "================================================================================"
printf "%-14s %-8s %-12s %-14s %-14s %-12s\n" "Partition" "Status" "TimeLimit" "RAM/Core" "Total RAM/Node" "Idle/Total"
printf "%-14s %-8s %-12s %-14s %-14s %-12s\n" "----------" "------" "---------" "--------" "--------------" "----------"

# 定義各分區記憶體規格 (MB)
declare -A PER_CORE_MEM
PER_CORE_MEM["development"]="4.3 GB (4308M)"
PER_CORE_MEM["ct112"]="4.3 GB (4308M)"
PER_CORE_MEM["cf112"]="8.9 GB (8916M)"
PER_CORE_MEM["hm112"]="18.1 GB (18130M)"

for p in development ct112 cf112 hm112; do
    info=$(sinfo -p "$p" -o "%a %l %m" -h 2>/dev/null | head -n 1)
    if [ -n "$info" ]; then
        avail=$(echo "$info" | awk '{print $1}')
        limit=$(echo "$info" | awk '{print $2}')
        node_mem=$(echo "$info" | awk '{print $3}')
        node_ram_gb=$(awk "BEGIN {printf \"%.0f GB\", $node_mem/1024}")
        core_ram="${PER_CORE_MEM[$p]:-4.3 GB}"
        
        # 計算 idle 節點與總節點數
        summary=$(sinfo -p "$p" -o "%D %T" -h 2>/dev/null)
        total_nodes=$(echo "$summary" | awk '{sum+=$1} END {print sum}')
        idle_nodes=$(echo "$summary" | awk '$2=="idle" {sum+=$1} END {print (sum==""?0:sum)}')
        
        printf "%-14s %-8s %-12s %-14s %-14s %s/%s\n" "$p" "$avail" "$limit" "$core_ram" "$node_ram_gb" "$idle_nodes" "$total_nodes"
    fi
done

echo ""
echo "💡 提示："
echo "  1. 派送前使用 'sbatch --test-only <script.slurm>' 進行免扣點模擬預檢。"
echo "  2. 登入節點禁止使用 'sbatch -p vscode' 或 'sbatch -p visual' (限專屬節點或 OOD 派送)。"
echo "================================================================================"
