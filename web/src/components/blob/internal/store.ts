import { writable } from 'svelte/store'
import type { Writable } from 'svelte/store'

export interface BlobProps {
  x: number
  y: number
  scale: number
  rotate: number
  zIndex: number
}

export type BlobPropsInput = Partial<BlobProps>

export function getBlobProps(overrides: BlobPropsInput = {}): BlobProps {
  return {
    x: 0,
    y: 0,
    scale: 1.2,
    rotate: 0,
    zIndex: -1,
    ...overrides,
  }
}

export default (): Writable<BlobPropsInput> & {
  width: number
  height: number
} => {
  const { subscribe, update } = writable<BlobPropsInput>(getBlobProps())
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
