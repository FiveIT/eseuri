<script lang="ts">
  import { tick } from 'svelte'
  import { goto, url, isActive } from '@roxi/routify'

  import { alive } from './Layout.svelte'

  export let href: string

  const go = () => {
    // eslint-disable-next-line no-unused-vars
    $alive = false
    tick().then(() => $goto(href))
  }
</script>

<a
  href={$url(href)}
  on:click|preventDefault={go}
  class="w-auto h-auto"
  class:pointer-events-none={$isActive(href)}>
  <slot />
</a>
