#!/bin/bash

CODE_SERVER="$HOME/.local/bin/code-server"

# 隨機取得空閒 port
myport=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")

# Login node hostname，例如 ilgn01
myhostname=$(hostname -s)

# 讀取私人密碼
export PASSWORD=$(cat "$HOME/.code-server-password")

# 嘗試使用 OOD rnode proxy
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

~

~

