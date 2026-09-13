#!/bin/bash
#SBATCH --account=GOV114022
#SBATCH --job-name=code-server
#SBATCH --partition=ct112
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-node=1
#SBATCH --time=04:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

# ==============================================================================
# sbatch_code_cpu.slurm - 在 Compute Node (計算節點) 透過 Slurm 排程運行 Code-Server
# 提交指令: sbatch sbatch_code_cpu.slurm
# ==============================================================================

echo "=========================================================="
echo "作業啟動時間 : $(date)"
echo "執行計算節點 : $(hostname -s)"
echo "作業任務 ID  : ${SLURM_JOB_ID}"
echo "分配 CPU 核心: ${SLURM_CPUS_PER_TASK}"
echo "=========================================================="

# 1. 尋找可用之 code-server 執行檔
if [ -x "${HOME}/.local/bin/code-server" ]; then
    CODE_SERVER="${HOME}/.local/bin/code-server"
elif command -v code-server &>/dev/null; then
    CODE_SERVER="$(command -v code-server)"
else
    # 嘗試由系統模組載入
    module load tools/code-server 2>/dev/null || true
    if command -v code-server &>/dev/null; then
        CODE_SERVER="$(command -v code-server)"
    else
        echo "❌ 錯誤: 找不到 code-server 執行檔！"
        exit 1
    fi
fi

# 2. 動態取得計算節點未被佔用的 Port
myport=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
myhostname=$(hostname -s)

# 3. 讀取密碼檔
PASSWORD_FILE="${HOME}/.code-server-password"
if [ ! -f "${PASSWORD_FILE}" ]; then
    echo "admin12345" > "${PASSWORD_FILE}"
    chmod 600 "${PASSWORD_FILE}"
fi
export PASSWORD=$(cat "${PASSWORD_FILE}" | tr -d '\r\n')

# 4. 組裝國網中心 Open OnDemand 存取網址
url="https://f1-stn01.nchc.org.tw/rnode/${myhostname}/${myport}/?folder=${HOME}"
url_backup="https://f1-stn02.nchc.org.tw/node/${myhostname}/${myport}/?folder=${HOME}"

# 同時記錄到家目錄下的專屬文字檔，便於直接在 Login Node 查詢
cat <<EOF > "${HOME}/.code-server-slurm-url.txt"
Job ID     : ${SLURM_JOB_ID}
Node       : ${myhostname}
Port       : ${myport}
OOD 網址 (主要): ${url}
OOD 網址 (備援): ${url_backup}
EOF

echo "----------------------------------------------------------"
echo "🌐 Code-Server 存取網址已生成："
echo "👉 主要網址: ${url}"
echo "👉 備用網址: ${url_backup}"
echo "----------------------------------------------------------"
echo "執行版本: $("${CODE_SERVER}" --version | head -1)"
echo "開始監聽 0.0.0.0:${myport}..."
echo "=========================================================="

# 5. 可選：若有使用第 7 章 Proxy，自動載入計算節點外網代理 (供下載外網擴充套件或 git)
PROXY_ENV="${HOME}/hpc-tutorial/07-compute-node-proxy/scripts/set_compute_env.sh"
if [ -f "${PROXY_ENV}" ]; then
    source "${PROXY_ENV}" 2>/dev/null || true
fi

# 6. 啟動 code-server (綁定 0.0.0.0 確保所有網路介面皆可轉發)
exec "${CODE_SERVER}" \
  --bind-addr "0.0.0.0:${myport}" \
  --auth password \
  --cert false \
  "${HOME}"
