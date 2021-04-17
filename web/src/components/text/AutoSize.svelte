<script lang="ts">
  import { onMount } from 'svelte'

  export let min = 1
  export let max = 1
  export let unit = 0.01

  let fontSize: number
  let parentHeight: number
  export let textHeight: number

  onMount(() => {
    let l = min
    let r = max
    let u = unit
    fontSize = l

    while (l <= r) {
      const m = l + (r - l) / 2

      fontSize = m
      if (Math.abs(parentHeight - textHeight) < unit) {
        break
      }

      if (textHeight < parentHeight) {
        l = r + u
      } else {
        r = l - u
      }
      u /= 2
    }
  })
</script>

<div bind:offsetHeight={parentHeight} class="w-full h-full">
  <slot {fontSize} />
</div>
