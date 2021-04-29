import { defineConfig } from 'vite-plugin-windicss'
import defaults from 'windicss/defaultTheme'

export default defineConfig({
  theme: {
    colors: {
      orange: '#FF7F11',
      red: 'var(--red, #FF3F00)',
      blue: 'var(--darkblue,#485696)',
      green: '#008148',
      lightgreen: 'var(--light-green, #00e781)',
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
    },
    borderRadius: {
      DEFAULT: '0.625rem',
      full: '9999px',
    },
    boxShadow: {
      soft: 'var(--shadow-soft)',
      'inner-soft': 'inset var(--shadow-soft)',
      DEFAULT: 'var(--shadow)',
      inner: 'inset var(--shadow)',
      large: 'var(--shadow-large)',
      'inner-large': 'inset var(--shadow-large)',
      none: 'none',
    },
    gridAutoRows: {
      layout: 'minmax(var(--row-height), max-content)',
      essays: 'var(--essay-row-heigth)',
    },
    gridTemplateColumns: {
      layout: 'repeat(6, var(--column-width))',
      essays: 'repeat(3, var(--essay-column-width))',
    },
    gridAutoColumns: {
      layout: 'var(--column-width)',
    },
    extend: {
      maxWidth: {
        layout: 'calc(6 * var(--column-width) + 5 * var(--essay-column-gap))',
      },
      width: {
        notification: ' var(--essay-column-width)',
      },
      height: {
        notification: 'var(--row-height)',
      },
      minHeight: {
        notification: 'var(--row-height)',
      },
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
    'shadow',
    'shadow-inner',
    [].concat(
      ...'soft,large'.split(',').map(v => [`shadow-${v}`, `shadow-inner-${v}`])
    ),
  ],
  darkMode: false,
  preflight: true,
  transformCSS: 'post',
})
