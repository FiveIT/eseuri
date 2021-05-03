import { defineConfig } from 'vite-plugin-windicss'
import defaults from 'windicss/defaultTheme'

export default defineConfig({
  theme: {
    colors: {
      orange: '#FF7F11',
      red: '#FF3F00',
      blue: 'var(--blue, #485696)',
      green: '#008148',
      neongreen: '#00E781',
      current: 'currentColor',
      transparent: 'transparent',
      white: 'var(--white, #FCFAF9)',
      black: 'var(--black, #000000)',
      gray: {
        light: 'var(--light-gray, #DADADA)',
        DEFAULT: 'var(--gray, #939393)',
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
        '3.5rem',
        {
          lineHeight: '100%',
          letterSpacing: '-0.225rem',
        },
      ],
      workInfo: ['1.125rem', { letterSpacing: '-0.055rem', lineHeight: '90%' }],
    },
    spacing: {
      xs: 'calc(var(--row-gap) / 2)',
      sm: 'var(--row-gap)',
      md: '1.25rem',
      lg: 'var(--essay-column-gap)',
      xlg: '6.5vmin',
      associationboxwidth: 'var(--association-box-width)',
      associationboxheight: 'var(--association-box-height)',
      deleteboxwidth: 'var(--delete-box-width)',
      configureloginwidth: 'var(--configure-login-width)',
      columnwidth: 'var(--column-width)',
      rowheight: 'var(--row-height)',
      buttonleft: '13vmin',
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
      layout: 'minmax(var(--row-height), max-content)',
      essays: 'var(--essay-row-heigth)',
    },
    gridTemplateColumns: {
      layout: 'repeat(6, 1fr)',
      essays: 'repeat(3, var(--essay-column-width))',
    },
    gridAutoColumns: {
      layout: 'var(--column-width)',
    },
    maxWidth: {
      layout: 'calc(6 * var(--column-width) + 5 * var(--essay-column-gap))',
    },
  },
  safelist: [
    'underline',
    [].concat(...['white', 'black'].map(v => [`text-${v}`, `border-${v}`])),
    [2, 3].map(v => `border-${v}`),
    ...Array.from({ length: 6 }, (_, i) =>
      ['row', 'col'].map(v => `${v}-start-${i + 1}`)
    ),
    'bg-white-50',
    'pointer-events-none',
    'w-full',
    'h-full',
    ['lg', 'xl'].map(v => `text-${v}`),
    'my-auto',
    ['white', 'blue', 'google-docs', 'red'].map(v => `bg-${v}`),
    'border',
    'cursor-default',
    'font-sans',
    'antialiased',
    'text-sm',
    ['0.02', '1'].map(v => `pt-${v}`),
    'px-sm',
    'py-xs',
    'grid-cols-3',
    'w-associationboxwidth',
    'h-associationboxheight',
  ],
  darkMode: false,
  preflight: true,
  transformCSS: 'post',
})
