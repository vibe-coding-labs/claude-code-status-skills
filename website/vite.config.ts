import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// GitHub Pages 项目站点挂在 /<repo>/ 下, 本地开发保持根路径。
export default defineConfig({
  plugins: [react()],
  base: process.env.PAGES_BASE ?? '/',
})
