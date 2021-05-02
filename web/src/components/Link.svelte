<script lang="ts" context="module">
  import type { GotoHelper } from '@roxi/routify'
  import { goto, isActive, url } from '@roxi/routify'
  import { createEventDispatcher, tick } from 'svelte'
  import type { Writable } from 'svelte/store'
  import { getLayout } from './Layout.svelte'

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

  const { alive } = getLayout()

  export let href = '/'
  export let disable = $isActive(href, undefined, { strict: false })
  export let hideIfDisabled = false
</script>

{#if !disable}
  <a
    href={$url(href)}
    on:click|preventDefault={() => {
      dispatch('navigate', { href })
      go(href, alive, $goto)
    }}
    class="w-auto h-auto select-none">
    <slot {disable} {href} />
  </a>
{:else if !hideIfDisabled}
  <slot {disable} {href} />
{/if}
