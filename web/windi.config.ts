import defaults from 'windicss/defaultTheme'
import { defineConfig } from 'vite-plugin-windicss'

/**
 * @type {import('windicss/types/interfaces').Config}
 */
export default defineConfig({
  theme: {
    colors: {
      orange: '#FF7F11',
      red: '#FF3F00',
      blue: '#485696',
      green: '#008148',
      current: 'currentColor',
      transparent: 'transparent',
      white: '#FCFAF9',
      black: '#000000',
      gray: {
        light: '#DADADA',
        DEFAULT: '#939393',
        dark: '#4F4F4F',
      },
      facebook: '#3B5998',
      google: {
        DEFAULT: '#DE5246',
        docs: '#337DFA',
      },
    },
    fontFamily: {
      sans: ['Carme', ...defaults.fontFamily.sans],
      serif: ['Cardo', ...defaults.fontFamily.serif],
    },
    fontSize: {
      sm: ['1rem', { letterSpacing: '-0.055rem' }],
      md: ['1.75rem', { letterSpacing: '-0.125rem' }],
      lg: ['2.5rem', { letterSpacing: '-0.1rem' }],
      xl: ['6rem', { letterSpacing: '-0.2rem' }],
      prose: [
        '1.125rem',
        {
          lineHeight: '150%',
          letterSpacing: '0.007rem',
        },
      ],
      title: [
        '2.625rem',
        {
          lineHeight: '100%',
          letterSpacing: '-0.225rem',
        },
      ],
    },
    spacing: {
      sm: 'var(--row-gap)',
      md: '1.25rem',
      lg: 'var(--essay-column-gap)',
      xlg: '3.700rem',
    },
    borderRadius: {
      DEFAULT: '0.625rem',
      full: '9999px',
    },
    boxShadow: {
      soft: 'var(--shadow-soft)',
      DEFAULT: 'var(--shadow)',
      large: 'var(--shadow-large)',
      none: 'none',
    },
    gridAutoRows: {
      layout: 'var(--row-height)',
      essays: 'var(--essay-row-heigth)',
    },
    gridTemplateColumns: {
      layout: 'repeat(6, 1fr)',
      essays: 'repeat(3, 1fr)',
    },

    maxWidth: {
      layout: 'calc(6 * var(--column-width) + 5 * var(--essay-column-gap))',
    },
  },
  darkMode: false,
  preflight: true,
  transformCSS: 'post',
})
