<script lang="ts" context="module">
  import type { GotoHelper } from '@roxi/routify'
  import { goto, isActive, url } from '@roxi/routify'
  import { createEventDispatcher, tick } from 'svelte'
  import type { Writable } from 'svelte/store'

  import { getLayout } from '$/components'

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
  export let disable: boolean | undefined = undefined
  export let hideIfDisabled = false
  export let directGoto = false
  export let title: string | undefined = undefined

  $: isDisabled =
    typeof disable === 'undefined' ? $isActive(href, undefined, { strict: false }) : disable
</script>

{#if !isDisabled}
  <a
    href={$url(href)}
    on:click|preventDefault={() => {
      dispatch('navigate', { href })
      if (directGoto) {
        $goto(href)
      } else {
        go(href, alive, $goto)
      }
    }}
    class="group w-auto h-auto select-none"
    {title}>
    <slot tabindex={undefined} disable={false} {href} />
  </a>
{:else if !hideIfDisabled}
  <slot tabindex={0} disable {href} />
{/if}
