# Compute Node Proxy & Security Skill

針對國網中心創進一號（Taiwania 1 / f1）與通用 HPC 叢集量身打造的**計算節點連網穿透與代理安全專家技能**。

---

## 🎯 核心功能

1. **實體隔離外網穿透**：解決計算節點（Compute Node）無直接外網，無法下載 Hugging Face 模型、PyPI 套件或呼叫 API 的痛點。
2. **資安關鍵防護**：自動管理 `~/.proxy_auth` 憑證檔（強制 `chmod 600`），徹底杜絕在 `ps aux` 指令列中暴露明文帳號密碼。
3. **精確 `no_proxy` 配置**：預設排除叢集內網（`localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12`），確保節點間 MPI 通訊正常；嚴格避免使用 `*.nchc.org.tw` 萬用字元，防止公開網站（如 `www.nchc.org.tw`）連線超時。
4. **Fail-Fast 5 秒連線預檢**：在 Slurm 腳本頂部自動加入輕量連線檢查，網路不通時立即退出，不浪費任何寶貴的計算額度（SU）。
5. **完整自包含工具庫**：內建所有啟動、停止、環境注入與診斷腳本，完全獨立運作，免依賴外部教學目錄。

---

## 📁 目錄結構

```text
compute-node-proxy/
├── SKILL.md                          # 核心技能指引、引導問答規範與防呆守則
├── README.md                         # 說明文件
├── scripts/                          # 完整自包含腳本庫
│   ├── check_proxy.sh                # 診斷登入節點 Proxy 狀態與內網 IP
│   ├── test_compute_connection.sh    # 計算節點連通性快速測試 (含 5 秒逾時保護)
│   ├── start.sh                      # 登入節點一鍵啟動 Proxy 常駐服務 (tmux: http-proxy)
│   ├── stop.sh                       # 登入節點一鍵關閉 Proxy 常駐服務
│   ├── set_compute_env.sh            # 計算節點載入 http_proxy / https_proxy / 精確 no_proxy
│   ├── start_proxy.py                # 輕量 Python Proxy 守護核心
│   └── setup_env.sh                  # 虛擬環境與 proxy.py 套件自動部署
└── templates/
    └── job_with_proxy.slurm          # 具備 Fail-Fast 預檢與安全憑證載入的 Slurm 排程範本
```

---

## 🚀 常用指令速查

### 1. 登入節點：啟動 Proxy 服務
```bash
bash <此 skill 的 scripts 目錄>/start.sh
```

### 2. 登入節點：診斷 Proxy 狀態與 IP
```bash
bash <此 skill 的 scripts 目錄>/check_proxy.sh
```

### 3. 計算節點：測試外網連線
```bash
bash <此 skill 的 scripts 目錄>/test_compute_connection.sh
```

### 4. 登入節點：關閉 Proxy 服務 (釋放資源)
```bash
bash <此 skill 的 scripts 目錄>/stop.sh
```
