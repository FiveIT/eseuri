<script lang="ts">
  import type { WorkType } from '$/lib'
  import { px } from '$/lib'
  import { goto, isActive } from '@roxi/routify'
  import Search from 'svelte-material-icons/Magnify.svelte'
  import { go, getLayout } from '.'

  const { alive } = getLayout()

  export let query: string = ''
  export let type: WorkType = 'essay'

  $: if (query === ' ') {
    query = ''
  } else if (query.endsWith('  ')) {
    query = query.trim() + ' '
  }
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

  function doSearch() {
    if (query === '') {
      return
    }
    if (isHome) {
      go('/search', alive, $goto, { query, type })
    } else if (isSearch) {
      $goto('/search', { query, type })
    }
  }
</script>

<div class="flex flex-row items-center">
  <button class="my-auto pt-{isHome ? '0.02' : 1} h-full ml-sm" on:click={doSearch}>
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
    on:keyup={ev => ev.code === 'Enter' && doSearch()}
    bind:value={query} />
</div>
