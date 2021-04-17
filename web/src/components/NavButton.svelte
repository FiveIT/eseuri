<script lang="ts">
  import { getContext } from 'svelte'

  import Link from './Link.svelte'

  import type { Context } from './Layout.svelte'
  import { contextKey } from './Layout.svelte'

  const { theme: themeStore } = getContext<Context>(contextKey)

  import { isActive } from '@roxi/routify'

  import { text, filterShadow } from '$/theme'

  export let href = '/'
  export let enable = !$isActive(href)
  export let hideIfDisabled = false
  export let theme = $themeStore
</script>

<Link {href} {enable} {hideIfDisabled} on:navigate>
  <div
    class="w-full h-full flex justify-center items-center font-sans no-underline text-sm {text[
      theme
    ]} {filterShadow[theme]}">
    <slot />
  </div>
</Link>
