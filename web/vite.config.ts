// vite.config.js
import { defineConfig } from 'vite'
import { minify } from 'html-minifier'
import path from 'path'
import preprocess from 'svelte-preprocess'
import svelte from '@sveltejs/vite-plugin-svelte'
import windiCSS from 'vite-plugin-windicss'

const indexReplace = () => {
  return {
    name: 'html-transform',
    transformIndexHtml(html) {
      return minify(html, {
        collapseWhitespace: true,
      })
    },
  }
}

export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production'
  return {
    extensions: ['ts', 'html', 'js', 'css', 'svg', 'json'],
    optimizeDeps: {
      exclude: ['@roxi/routify', 'pug', '@urql/svelte', '@tmaxmax/svelte-auth0'],
    },
    resolve: {
      dedupe: ['@roxi/routify'],
      alias: {
        svelte: path.resolve(process.cwd(), 'node_modules/svelte'),
        $: path.resolve(process.cwd(), 'src'),
      },
    },
    plugins: [
      svelte({
        hot: !isProduction,
        compilerOptions: {
          dev: !isProduction,
        },
        emitCss: true,
        preprocess: preprocess(),
      }),
      windiCSS.default(),
      indexReplace(),
    ],
    build: {
      minify: isProduction,
    },
  }
})
