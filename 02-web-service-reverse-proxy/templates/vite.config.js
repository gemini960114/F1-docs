import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  
  // 核心設定 1：使用相對路徑打包所有 CSS/JS 靜態資源
  // 避免在 /rnode/<host>/<port>/ 下請求 /assets/* 觸發 404
  base: './',

  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: false,
    // 核心設定 2：放行反向代理標頭 (例如 f1-stn01.nchc.org.tw)
    // 避免出現 "Blocked request. This host is not allowed"
    allowedHosts: true,
  },

  preview: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: false,
    allowedHosts: true,
  }
});
