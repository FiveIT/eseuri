import type { Theme } from './types'

type ThemeEntry = Record<Theme, string>

export const text: ThemeEntry = {
  default: 'text-black',
  white: 'text-white',
}

export const border: Record<string, ThemeEntry> = {
  color: {
    default: 'border-black',
    white: 'border-white',
  },
  size: {
    default: 'border-2',
    white: 'border-3',
  },
}

export const filterShadow: ThemeEntry = {
  default: '',
  white: 'filter-shadow',
}
