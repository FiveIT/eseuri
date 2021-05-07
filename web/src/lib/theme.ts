import type { Theme } from '.'

export type ThemeEntry = Record<Theme, string>

export const text: ThemeEntry = {
  default: 'text-black',
  white: 'text-white',
}

export const placeholderText: ThemeEntry = {
  default: 'text-gray',
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

export const innerShadow: ThemeEntry = {
  default: '',
  white: 'shadow-inner-large',
}

export const background: ThemeEntry = {
  default: 'bg-white',
  white: 'bg-blue',
}

export const fontWeight: ThemeEntry = {
  default: 'font-light',
  white: '',
}
