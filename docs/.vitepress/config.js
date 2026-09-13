import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "國網創進一號 (F1) HPC 教學手冊",
  description: "以 Code-Server Web UI 為核心工作台的超級電腦全流程實戰指南",
  head: [
    ['link', { rel: 'icon', type: 'image/x-icon', href: 'https://www.nchc.org.tw/img/favicon.ico' }],
    ['link', { rel: 'shortcut icon', type: 'image/x-icon', href: 'https://www.nchc.org.tw/img/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#0284c7' }]
  ],
  base: '/F1-docs/',
  ignoreDeadLinks: true,
  themeConfig: {
    logo: 'https://www.nchc.org.tw/img/favicon.ico',
    nav: [
      { text: '首頁', link: '/' },
      { text: '課程大綱', link: '/guide/00_course_syllabus' },
      {
        text: '章節導覽',
        items: [
          { text: '第 01 章：SSH 登入與 2FA', link: '/guide/01_f1_ssh_and_2fa' },
          { text: '第 02 章：網頁服務反向代理', link: '/guide/02_web_service_reverse_proxy' },
          { text: '第 03 章：Code-Server 雲端工作台', link: '/guide/03_code_server_on_hpc' },
          { text: '第 04 章：AI 開發工具鏈與 Medusa', link: '/guide/04_ai_developer_tools' },
          { text: '第 05 章：AI 輔助生醫管線實作', link: '/guide/05_ai_assisted_bio_pipeline' },
          { text: '第 06 章：Slurm 語法與作業調度', link: '/guide/06_slurm_syntax_and_job_management' },
          { text: '第 07 章：突破網路隔離 HTTP Proxy', link: '/guide/07_compute_node_proxy' },
          { text: '第 08 章：AI Agent 自動化排程管線', link: '/guide/08_ai_agent_slurm_pipeline' }
        ]
      },
      { text: 'AI 規範 (AGENTS.md)', link: '/guide/agents_governance' },
      { text: '創進一號官方手冊', link: 'https://man.twcc.ai/@f1-manual/manual' }
    ],
    sidebar: [
      {
        text: '🚀 第一階段：起跑與建置雲端工作台',
        items: [
          { text: '📌 課程總綱與學習地圖', link: '/guide/00_course_syllabus' },
          { text: '🔑 第 01 章：登入節點與 2FA 認證', link: '/guide/01_f1_ssh_and_2fa' },
          { text: '🌐 第 02 章：網頁反向代理與動態埠', link: '/guide/02_web_service_reverse_proxy' },
          { text: '💻 第 03 章：Code-Server 瀏覽器工作台', link: '/guide/03_code_server_on_hpc' },
          { text: '🤖 第 04 章：AI 工具鏈與國網 Medusa', link: '/guide/04_ai_developer_tools' }
        ]
      },
      {
        text: '🔬 第二階段：工作台互動原型開發',
        items: [
          { text: '🧬 第 05 章：AI 輔助生醫質控管線', link: '/guide/05_ai_assisted_bio_pipeline' }
        ]
      },
      {
        text: '⚡ 第三階段：調度超級算力與突破隔離',
        items: [
          { text: '📊 第 06 章：Slurm 語法精講與作業調度', link: '/guide/06_slurm_syntax_and_job_management' },
          { text: '🛡️ 第 07 章：計算節點安全 HTTP Proxy', link: '/guide/07_compute_node_proxy' }
        ]
      },
      {
        text: '🎯 第四階段：終極整合與全流程自動化',
        items: [
          { text: '🚀 第 08 章：AI Agent 自動化排程派送', link: '/guide/08_ai_agent_slurm_pipeline' }
        ]
      },
      {
        text: '📜 規範與參考',
        items: [
          { text: '🛡️ HPC 專屬 AGENTS.md 治理守則', link: '/guide/agents_governance' }
        ]
      }
    ],
    search: {
      provider: 'local'
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/gemini960114/f1-docs' }
    ],
    footer: {
      message: '本教學手冊深度整合國網中心官方指南與實務踩坑經驗，實際配置請以各服務官方資訊為準。',
      copyright: 'Copyright © 2026 NCHC Taiwania 1 (f1) Tutorial'
    }
  }
})
