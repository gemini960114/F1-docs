#!/bin/bash
#!/bin/bash
#!/bin/bash
#!/bin/bash
#SBATCH --account=GOV114022
#SBATCH --job-name=code-server
#SBATCH --partition=ct112
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-node=1
#SBATCH --output=logs/job-%j.out
#SBATCH --error=logs/job-%j.err

# 使用自己安裝的 code-server
CODE_SERVER="$HOME/.local/bin/code-server"

# 隨機取得可用 port
myport=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")

# Compute node hostname
myhostname=$(hostname -s)

# 從私人檔案讀取密碼
export PASSWORD=$(cat "$HOME/.code-server-password")

# Open OnDemand URL
url="https://f1-stn01.nchc.org.tw/rnode/${myhostname}/${myport}/"

echo "Node=${myhostname}"
echo "Port=${myport}"
echo "URL=${url}"
echo "code-server=$(${CODE_SERVER} --version | head -1)"

${CODE_SERVER} \
  --bind-addr "${myhostname}:${myport}" \
  --auth password \
  --cert false \
  "$HOME"
