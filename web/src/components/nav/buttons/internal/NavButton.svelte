<script lang="ts">
  import Link from './Link.svelte'

  import { getLayout } from '$/components'
  import { text, filterShadow, TRANSITION_EASING as easing } from '$/lib'

  import { fade } from 'svelte/transition'

  const { theme: themeStore } = getLayout()

  export let href = '/'
  export let disable: boolean | undefined = undefined
  export let directGoto = false
  export let hideIfDisabled = false
  export let showTooltip = false
  export let theme = $themeStore
  export let title: string | undefined = undefined
</script>

<Link {href} {disable} {hideIfDisabled} {directGoto} on:navigate {title} let:selected>
  <div
    class="group relative w-full h-full flex justify-center items-center font-sans no-underline text-sm antialiased select-none {text[
      theme
    ]} {filterShadow[theme]}"
    class:cursor-default={disable}>
    <slot {disable} {selected} />
    {#if title && showTooltip && !(disable && hideIfDisabled)}
      <p
        class="absolute hidden text-white text-0.8em top-3/4 text-center bg-black p-sm rounded group-hover:block">
        {title}
      </p>
    {/if}
  </div>
</Link>
