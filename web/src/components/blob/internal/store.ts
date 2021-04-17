import type { Writable } from 'svelte/store'
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

export type BlobPropsInput = Partial<BlobProps>

export function getBlobProps(overrides: BlobPropsInput = {}): BlobProps {
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
    ...overrides,
  }
}

export default (): Writable<BlobPropsInput> & {
  width: number
  height: number
} => {
  const { subscribe, update } = tweened<BlobPropsInput>(getBlobProps(), {
    duration,
    easing,
  })
  return {
    subscribe,
    set(input) {
      update(prev => ({
        ...prev,
        ...input,
      }))
    },
    update(fn) {
      update(prev => ({
        ...prev,
        ...fn(prev),
      }))
    },
    width: 0,
    height: 0,
  }
}
