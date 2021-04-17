<script lang="ts">
  import { getContext } from 'svelte'
  import Search from 'svelte-material-icons/Magnify.svelte'

  import { isActive, goto } from '@roxi/routify'

  import type { Context } from './Layout.svelte'
  import { contextKey } from './Layout.svelte'
  import { go } from './Link.svelte'

  import type { WorkType } from '$/types'

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
    size = '1.125rem'
  } else if (isSearch) {
    size = '1.75rem'
  }

  function doSearch(condition = true) {
    if (query === '') {
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
  <button class="my-auto h-full ml-sm" on:click={onClick}>
    <Search color="var(--white)" {size} />
  </button>
  <input
    type="text"
    class="font-sans text-sm subpixel-antialiased my-auto bg-transparent placeholder-white text-white ml-sm w-full"
    class:text-md={isSearch}
    class:filter-shadow={isHome}
    class:filter-shadow-soft={isSearch}
    placeholder="Caută titluri sau personaje"
    bind:this={input}
    on:keydown={onKeydown}
    bind:value={query} />
</div>
