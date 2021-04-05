import { cubicOut as easing } from 'svelte/easing'
import { tweened } from 'svelte/motion'

export default () => {
  const { subscribe, set } = tweened(
    {
      x: 0,
      y: 0,
      scale: 1.2,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
    },
    {
      duration: 300,
      easing,
    }
  )

  return {
    subscribe,
    set,
    width: 0,
    height: 0,
  }
}
