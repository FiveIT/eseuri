<script lang="ts">
  import { fade } from 'svelte/transition'

  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
  } from '$/lib/globals'
  import type { BlobPropsInput } from './store'

  export let props: BlobPropsInput = {}

  export let width: number
  export let height: number

  $: p = props
</script>

<div
  transition:fade={{ duration, easing }}
  class="fixed"
  style="left: {p.x}px; top: {p.y}px; transform: scale({p.scale}) rotate({p.rotate}deg); z-index: {p.zIndex};"
  bind:offsetWidth={width}
  bind:offsetHeight={height}>
  <slot />
</div>
