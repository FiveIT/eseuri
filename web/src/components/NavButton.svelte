<script lang="ts">
  import Link from './Link.svelte'
  import { getLayout } from './Layout.svelte'
  import { isActive } from '@roxi/routify'
  import { text, filterShadow } from '$/lib/theme'
  import { TRANSITION_EASING as easing } from '$/lib/globals'
  import { fade } from 'svelte/transition'

  const { theme: themeStore } = getLayout()

  export let href = '/'
  export let disable = $isActive(href, undefined, { strict: false })
  export let hideIfDisabled = false
  export let showTooltip = false
  export let theme = $themeStore
  export let title: string | undefined = undefined
</script>

<Link {href} {disable} {hideIfDisabled} on:navigate let:tabindex {title}>
  <div
    class="relative w-full h-full flex justify-center items-center font-sans no-underline text-sm antialiased select-none {text[
      theme
    ]} {filterShadow[theme]}"
    class:cursor-default={disable} {tabindex}>
    <slot />
    {#if title && showTooltip && !(disable && hideIfDisabled)}
      <p
        class="absolute hidden text-white text-0.8em top-3/4 text-center bg-black p-sm rounded"
        transition:fade={{ easing, duration: 50 }}>
        {title}
      </p>
    {/if}
  </div>
</Link>

<style>
  div:hover > p,
  div:focus > p {
    display: initial;
  }
</style>
