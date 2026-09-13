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

# ------------------------------------------------------------------------------
# 隔離登入節點 VS Code / Code-Server 環境變數 (關鍵防禦)
# 若由 Code-Server 內建終端執行 sbatch，Slurm 會將 VSCODE_IPC_HOOK_CLI 傳遞至計算節點。
# 這會導致計算節點上的 code-server 誤判為 CLI Client（嘗試連向登入節點不存在的 IPC Socket），
# 噴出 ENOENT 錯誤並於 1 秒內自我終止！
# ------------------------------------------------------------------------------
unset VSCODE_IPC_HOOK_CLI
unset VSCODE_GIT_IPC_HANDLE
unset VSCODE_PROXY_URI
unset VSCODE_GIT_ASKPASS_EXTRA_ARGS
unset VSCODE_GIT_ASKPASS_NODE
unset VSCODE_GIT_ASKPASS_MAIN
unset VSCODE_PYTHON_AUTOACTIVATE_GUARD
unset GIT_ASKPASS
unset TERM_PROGRAM
unset BROWSER

# 設定計算節點專屬的 XDG_RUNTIME_DIR (避免指向登入節點不存在的 /run/user/<uid>)
export XDG_RUNTIME_DIR="/tmp/run-${USER}-${SLURM_JOB_ID:-$$}"
mkdir -p -m 700 "${XDG_RUNTIME_DIR}"

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
