<script lang="ts" context="module">
  import type { GotoHelper } from '@roxi/routify'
  import { goto, isActive, url } from '@roxi/routify'
  import { createEventDispatcher, getContext, tick } from 'svelte'
  import type { Writable } from 'svelte/store'
  import type { Context } from './Layout.svelte'
  import { contextKey } from './Layout.svelte'

  export function go(
    href: string,
    alive: Writable<boolean>,
    gotoFn: GotoHelper,
    param?: Parameters<GotoHelper>[1]
  ) {
    alive.set(false)
    tick().then(() => gotoFn(href, param))
  }
</script>

<script lang="ts">
  const dispatch = createEventDispatcher()

  const { alive } = getContext<Context>(contextKey)

  export let href = '/'
  export let enable = !$isActive(href, undefined, { strict: false })
  export let hideIfDisabled = false
</script>

{#if enable}
  <a
    href={$url(href)}
    on:click|preventDefault={() => {
      dispatch('navigate', { href })
      go(href, alive, $goto)
    }}
    class="w-auto h-auto select-none">
    <slot {enable} {href} />
  </a>
{:else if !hideIfDisabled}
  <slot enable={false} href="" />
{/if}
