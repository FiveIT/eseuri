<script lang="ts">
  import Link from './Link.svelte'
  import { getLayout } from './Layout.svelte'
  import { isActive } from '@roxi/routify'
  import { text, filterShadow } from '$/theme'

  const { theme: themeStore } = getLayout()

  export let href = '/'
  export let disable = $isActive(href, undefined, { strict: false })
  export let hideIfDisabled = false
  export let theme = $themeStore
</script>

<Link {href} {disable} {hideIfDisabled} on:navigate>
  <div
    class="w-full h-full flex justify-center items-center font-sans no-underline text-sm antialiased select-none {text[
      theme
    ]} {filterShadow[theme]}"
    class:cursor-default={disable}>
    <slot />
  </div>
</Link>
