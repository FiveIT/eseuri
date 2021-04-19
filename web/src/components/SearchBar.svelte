<script lang="ts">
  import type { WorkType } from '$/types'
  import { px } from '$/util'
  import { goto, isActive } from '@roxi/routify'
  import { getContext } from 'svelte'
  import Search from 'svelte-material-icons/Magnify.svelte'
  import type { Context } from './Layout.svelte'
  import { contextKey } from './Layout.svelte'
  import { go } from './Link.svelte'

  const { alive } = getContext<Context>(contextKey)

  export let query: string = ''
  export let type: WorkType = 'essay'

  let input: HTMLInputElement

  export const focusInput = () => {
    input.focus()
  }

  $: isHome = $isActive('/index')
  $: isSearch = $isActive('/search')

  let size: string
  $: if (isHome) {
    size = px(1.125)
  } else if (isSearch) {
    size = px(1.75)
  }

  function doSearch(condition = true) {
    if (query === '') {
      if (isSearch) {
        $goto('/search', { type })
      }
      return
    }
    if (isHome && condition) {
      go('/search', alive, $goto, { query, type })
    } else if (isSearch) {
      $goto('/search', { query, type })
    }
  }

  function onKeydown(ev: KeyboardEvent) {
    doSearch(ev.code === 'Enter')
  }

  function onClick() {
    doSearch()
  }
</script>

<div class="flex flex-row items-center">
  <button
    class="my-auto pt-{isHome ? '0.02' : 1} h-full ml-sm"
    on:click={onClick}>
    <Search color="var(--white)" {size} />
  </button>
  <input
    type="text"
    class="font-sans text-sm antialiased my-auto bg-transparent placeholder-white text-white ml-sm w-full"
    class:text-md={isSearch}
    class:filter-shadow={isHome}
    class:filter-shadow-soft={isSearch}
    placeholder="Caută titluri sau personaje"
    bind:this={input}
    on:keyup={onKeydown}
    bind:value={query} />
</div>
