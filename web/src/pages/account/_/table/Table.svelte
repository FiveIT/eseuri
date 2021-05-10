<script context="module" lang="ts">
  import { getContext, setContext } from 'svelte'
  import type { Writable } from 'svelte/store'

  interface Context {
    cols: number
    rows: Writable<number>
  }

  const contextKey = {}

  function setTable(ctx: Context) {
    setContext(contextKey, ctx)
  }

  export function getTable(): Context {
    return getContext(contextKey)
  }
</script>

<script lang="ts">
  import { LayoutContext } from '$/components'
  import { text, filterShadow } from '$/lib'
  import { writable } from 'svelte/store'

  export let cols = 6
  export let start = 1

  const rows = writable(0)

  setTable({ cols, rows })
</script>

<LayoutContext let:theme>
  <div
    role="table"
    class="col-start-{start} col-span-{cols} grid grid-cols-{cols} auto-rows-layout gap-x-md gap-y-sm font-sans text-sm antialiased {text[
      theme
    ]} {filterShadow[theme]}"
    style="--row-span: {$rows}">
    <slot />
  </div>
</LayoutContext>

<style>
  div {
    grid-row: span var(--row-span) / span var(--row-span);
  }
</style>
