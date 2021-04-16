import { tweened } from 'svelte/motion'

import {
  TRANSITION_DURATION as duration,
  TRANSITION_EASING as easing,
} from '$/globals'

export interface BlobFlipProps {
  x: number
  y: number
}

export interface BlobProps {
  x: number
  y: number
  scale: number
  rotate: number
  flip: BlobFlipProps
  zIndex: number
}

export function defaultBlobProps(): BlobProps {
  return {
    x: 0,
    y: 0,
    scale: 1.2,
    rotate: 0,
    flip: {
      x: 0,
      y: 0,
    },
    zIndex: -1,
  }
}

export default () => {
  const { subscribe, set } = tweened<BlobProps>(defaultBlobProps(), {
    duration,
    easing,
  })

  return {
    subscribe,
    set,
    width: 0,
    height: 0,
  }
}
