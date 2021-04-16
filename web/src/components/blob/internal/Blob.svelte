<script lang="ts">
  import { fade } from 'svelte/transition'

  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
  } from '$/globals'
  import { defaultBlobProps } from './store'

  export let props = defaultBlobProps()

  export let width: number
  export let height: number

  let { x, y, scale, rotate, flip, zIndex } = props
  $: ({ x, y, scale, rotate, flip, zIndex } = props)
  $: flipX = flip.x * 180
  $: flipY = flip.y * 180
</script>

<div
  transition:fade={{ duration, easing }}
  class="fixed"
  style="--x: {x}px; --y: {y}px; --scale: {scale}; --rotate: {rotate}deg; --flipX: {flipX}deg; --flipY: {flipY}deg; --z-index: {zIndex};"
  bind:offsetWidth={width}
  bind:offsetHeight={height}>
  <slot />
</div>

<style>
  div {
    z-index: var(--z-index);
    top: var(--y);
    left: var(--x);
    transform: scale(var(--scale)) rotate(var(--rotate)) rotateX(var(--flipX))
      rotateY(var(--flipY));
  }
</style>
