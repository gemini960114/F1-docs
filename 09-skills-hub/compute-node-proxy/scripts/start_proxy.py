#!/usr/bin/env bash
# -*- coding: utf-8 -*-
""":"
# Bash wrapper allowing direct execution with the correct venv python
VENV_PYTHON="${HOME}/.venv-proxy/bin/python"
if [ ! -f "${VENV_PYTHON}" ]; then
    echo "錯誤: 找不到 ${VENV_PYTHON}，請先執行 ./setup_env.sh 進行安裝！" >&2
    exit 1
fi
exec "${VENV_PYTHON}" "$0" "$@"
"""

import os
import sys
from pathlib import Path
from proxy import Proxy, sleep_loop

def main():
    auth_file = Path.home() / ".proxy_auth"
    basic_auth = None

    # 1. 優先從具有權限保護的 ~/.proxy_auth 讀取帳密
    if auth_file.exists():
        basic_auth = auth_file.read_text().strip()
    # 2. 次要從環境變數 PROXY_AUTH 讀取
    elif "PROXY_AUTH" in os.environ:
        basic_auth = os.environ["PROXY_AUTH"]

    # 3. 解析自訂參數，預設綁定 0.0.0.0 與 Port 8888
    args = list(sys.argv[1:])
    if "--hostname" not in args:
        args.extend(["--hostname", "0.0.0.0"])
    if "--port" not in args:
        args.extend(["--port", "8888"])

    # 4. 在內部注入 basic-auth，避免暴露在 ps aux / /proc 中
    if basic_auth and "--basic-auth" not in args:
        args.extend(["--basic-auth", basic_auth])

    with Proxy(args) as p:
        sleep_loop(p)

if __name__ == "__main__":
    main()
