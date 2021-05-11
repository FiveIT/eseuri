<script lang="ts">
  import { px } from '$/lib'

  export let fg: 'black' | 'white' = 'white'
  export let bg: string
  export let border = false
  export let icon: any
</script>

<div
  class="flex items-center p-sm rounded bg-{bg} text-{fg} justify-between select-none"
  class:border>
  <slot />
  <svelte:component this={icon} color={`var(--${fg})`} size={px(1.5)} />
</div>
