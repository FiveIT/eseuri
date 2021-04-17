<script lang="ts" context="module">
  import { tick, getContext } from 'svelte'
  import type { Writable } from 'svelte/store'
  import type { GotoHelper } from '@roxi/routify'

  import { contextKey } from './Layout.svelte'
  import type { Context } from './Layout.svelte'

  export function go(
    href: string,
    alive: Writable<boolean>,
    gotoFn: GotoHelper,
    param?: Parameters<GotoHelper>[1]
  ) {
    alive.set(false)
    tick().then(() => gotoFn!(href, param))
  }
</script>

<script lang="ts">
  import { goto, url, isActive } from '@roxi/routify'
  import { createEventDispatcher } from 'svelte'

  const dispatch = createEventDispatcher()

  const { alive } = getContext<Context>(contextKey)

  export let href = '/'
  export let enable = !$isActive(href, undefined, { strict: false })
</script>

{#if enable}
  <a
    href={$url(href)}
    on:click|preventDefault={() => {
      dispatch('navigate', { href })
      go(href, alive, $goto)
    }}
    class="w-auto h-auto select-none">
    <slot />
  </a>
{:else}
  <slot />
{/if}
