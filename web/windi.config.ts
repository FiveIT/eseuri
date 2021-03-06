import { defineConfig } from 'vite-plugin-windicss'
import defaults from 'windicss/defaultTheme'

export default defineConfig({
  theme: {
    colors: {
      orange: 'var(--orange, #FF7F11)',
      red: 'var(--red, #FF3F00)',
      blue: 'var(--blue, #485696)',
      green: {
        DEFAULT: 'var(--green, #008148)',
        light: 'var(--green-light, #00E781)',
      },
      current: 'currentColor',
      transparent: 'transparent',
      white: 'var(--white, #FCFAF9)',
      black: 'var(--black, #000000)',
      gray: {
        light: 'var(--gray-light, #DADADA)',
        DEFAULT: 'var(--gray, #939393)',
        dark: 'var(--gray-dark, #4F4F4F)',
      },
      'google-docs': '#4688f4',
    },
    fontFamily: {
      sans: ['Sora', ...defaults.fontFamily.sans],
      serif: ['Cardo', ...defaults.fontFamily.serif],
    },
    fontSize: {
      sm: ['1rem', { letterSpacing: '-0.06rem' }],
      md: ['1.75rem', { letterSpacing: '-0.15rem' }],
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
        '3em',
        {
          lineHeight: '100%',
          letterSpacing: '-0.225rem',
        },
      ],
      workInfo: ['1.125rem', { letterSpacing: '-0.07rem', lineHeight: '90%' }],
    },
    spacing: {
      xs: 'calc(var(--row-gap) / 2)',
      sm: 'var(--row-gap)',
      md: 'var(--column-gap)',
      lg: 'var(--essay-column-gap)',
      xlg: '6.5vmin',
      col: 'var(--column-width)',
    },
    borderRadius: {
      DEFAULT: '0.625rem',
      overlay: '0.4rem',
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
      form: 'repeat(3, var(--column-width))',
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
        'delete-box': 'var(--delete-box-width)',
        submit: 'var(--configure-login-width)',
      },
      height: {
        notification: 'var(--row-height)',
        row: 'var(--row-height)',
      },
      minHeight: {
        notification: 'var(--row-height)',
      },
      animation: {
        'spin-a': 'spin 1s ease-in-out infinite',
        'spin-b': 'spin 1s cubic-bezier(.36,.14,.5,1) infinite',
      },
    },
  },
  safelist: [
    'underline',
    [].concat(
      ...['white', 'black', 'gray', 'red', 'orange'].map(v => [`text-${v}`, `border-${v}`])
    ),
    ...[1, 2, 3].map(v => [`border-${v}`, `border-t-${v}`, `border-b-${v}`]),
    ...Array.from({ length: 6 }, (_, i) =>
      [].concat(
        ...['row', 'col'].map(v => [
          `grid-${v}s-${i + 1}`,
          `${v}-start-${i + 1}`,
          `${v}-start-${i + 7}`,
          `${v}-span-${i + 1}`,
        ])
      )
    ),
    'bg-white-50',
    'pointer-events-none',
    'w-full',
    'h-full',
    ['lg', 'xl'].map(v => `text-${v}`),
    'my-auto',
    ['white', 'blue', 'google-docs', 'red', 'orange', 'gray-dark'].map(v => `bg-${v}`),
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
    'font-light',
    'mt-0.3em',
    'mt-0.33em',
    'top-4.5rem',
    'w-submit',
    'placeholder-gray',
    'placeholder-white',
    ...[4, 3, 2, 1.4].map(v => [`w-${v}em`, `h-${v}em`]),
    [].concat(...['soft', 'large'].map(v => [`shadow-${v}`, `shadow-inner-${v}`])),
  ],
})
