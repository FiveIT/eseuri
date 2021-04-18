<script lang="ts">
  import { fade } from 'svelte/transition'

  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
  } from '$/globals'
  import { getBlobProps } from './store'
  import type { BlobPropsInput } from './store'

  export let props: BlobPropsInput = {}

  export let width: number
  export let height: number

  $: p = getBlobProps(props)
</script>

<div
  transition:fade={{ duration, easing }}
  class="fixed"
  style="--x: {p.x}px; --y: {p.y}px; --scale: {p.scale}; --rotate: {p.rotate}deg; --flip-x: {p
    .flip.x}deg; --flip-y: {p.flip.y}deg; --z-index: {p.zIndex};"
  bind:offsetWidth={width}
  bind:offsetHeight={height}>
  <slot />
</div>

<style>
  div {
    z-index: var(--z-index);
    top: var(--y);
    left: var(--x);
    transform: scale(var(--scale)) rotate(var(--rotate)) rotateX(var(--flip-x))
      rotateY(var(--flip-y));
  }
</style>
