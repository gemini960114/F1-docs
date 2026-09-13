---
layout: home

hero:
  name: "國網創進一號 (f1) HPC 實戰手冊"
  text: "以 Code-Server Web UI 為核心工作台"
  tagline: "徹底告別純終端與 Vim！從 SSH/2FA 一次性起跑、反向代理、VS Code 雲端工作台、AI 工具鏈到生醫管線、Slurm 排程與計算節點 Proxy 穿透"
  actions:
    - theme: brand
      text: 進入課程總綱
      link: /guide/00_course_syllabus
    - theme: alt
      text: 創進一號官方手冊
      link: https://man.twcc.ai/@f1-manual/manual

features:
  - icon: 🔑
    title: 第 01 章｜登入節點與 2FA 認證
    details: 解析四大前端伺服器 (ilgn/dtn/intgpn/stn)、IDExpert 2FA、三大儲存空間 (/home vs /work1 配額原則) 與極速 uv 套件管理。
    link: /guide/01_f1_ssh_and_2fa
    linkText: 探索連線與環境
  - icon: 🌐
    title: 第 02 章｜網頁服務反向代理
    details: 剖析 Open OnDemand 子路徑代理機制 (/rnode/<host>/<port>/)、動態連接埠分配，防範 nohup 的 SIGTTIN 背景死鎖。
    link: /guide/02_web_service_reverse_proxy
    linkText: 學習反向代理技術
  - icon: 💻
    title: 第 03 章｜Code-Server 雲端工作台
    details: 🚀 全面移師瀏覽器！深入掌握整合終端機、Open VSX 套件市集、視覺化 Git、Jupyter 虛擬環境綁定與斷點除錯實務。
    link: /guide/03_code_server_on_hpc
    linkText: 打造全功能雲端 IDE
  - icon: 🤖
    title: 第 04 章｜AI 開發工具鏈與 Medusa
    details: 於 Code-Server 內安裝 AI 擴充套件，設定 OpenCode CLI 串接國網 Medusa 地端大模型，並整合官方 Ollama 本地部署方案。
    link: /guide/04_ai_developer_tools
    linkText: 配置超算 AI 助手
  - icon: 🧬
    title: 第 05 章｜AI 輔助生醫質控管線
    details: 以 FASTQ 質控為跨領域通用範例，指揮 AI 編寫分析流程，於 Code-Server 整合終端測試並在瀏覽器即時預覽互動 HTML 報表。
    link: /guide/05_ai_assisted_bio_pipeline
    linkText: 快速原型與數據探索
  - icon: 📊
    title: 第 06 章｜Slurm 語法精講與作業調度
    details: 官方規格詳解 (ct112/cf112/arm144)、資源配置黃金三角、郵件狀態通知、seff 效能與 OOM 診斷，以及 Singularity 容器排程。
    link: /guide/06_slurm_syntax_and_job_management
    linkText: 規模化調度超級算力
  - icon: 🛡️
    title: 第 07 章｜計算節點安全 HTTP Proxy
    details: 解決計算節點無外網無法下載模型或資料的痛點，透過 Login Node 搭建具備密碼安全防護的 InfiniBand HTTP Proxy 隧道。
    link: /guide/07_compute_node_proxy
    linkText: 突破網路隔離限制
  - icon: 🚀
    title: 第 08 章｜AI Agent 自動化排程管線
    details: 【全系列集大成】在 Code-Server 中引導 AI Agent 自動將分析管線重構為 Slurm 批次作業，涵蓋純離線與 Proxy 動態下載雙模式！
    link: /guide/08_ai_agent_slurm_pipeline
    linkText: 實現全流程自主調度
  - icon: 📜
    title: 附錄｜HPC 專屬 AGENTS.md 守則
    details: 專為超級電腦量身定制的 AI Agent 治理規範：嚴禁 sudo、耗時任務強制改寫 Slurm、大資料強制放置 /work1 高速儲存區。
    link: /guide/agents_governance
    linkText: 查看 AI 治理守則
---
