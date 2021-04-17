<script lang="ts">
  import { tick, getContext } from 'svelte'
  import { goto, url, isActive } from '@roxi/routify'

  import { contextKey } from './Layout.svelte'
  import type { Context } from './Layout.svelte'

  export let href = '/'
  export let enable = !$isActive(href)

  const { alive } = getContext<Context>(contextKey)

  const go = () => {
    if (!enable) {
      return
    }
    // eslint-disable-next-line no-unused-vars
    $alive = false
    tick().then(() => $goto(href))
  }
</script>

<a
  href={$url(href)}
  on:click|preventDefault={go}
  class="w-auto h-auto select-none"
  class:pointer-events-none={!enable}>
  <slot />
</a>
