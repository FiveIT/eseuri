<script lang="ts">
  import { goto } from '@roxi/routify'
  import { tick } from 'svelte'
  import Search from 'svelte-material-icons/Magnify.svelte'
  export let page_name: string | undefined
  let Place_holder: string | undefined
  if (page_name === undefined) {
    Place_holder = 'Caută titluri sau personaje'
  } else {
    Place_holder = decodeURI(page_name)
  }
  export let isBig = false
  export let isAtHome = false
  export let alive: boolean
  let element: string
  let address: string
  async function goTo(href: string) {
    if (isAtHome) alive = false
    else alive = true
    await tick()
    $goto(href)
  }
  function handleKeydown(event: KeyboardEvent) {
    if (event.key == 'Enter') {
      if (isAtHome) {
        address = './search/' + element
      } else {
        address = './' + element
      }
      goTo(address)
    }
  }
  function search() {
    if (isAtHome) {
      address = './search/' + element
    } else {
      address = './' + element
    }
    goTo(address)
  }
</script>

<div class="flex flex-row items-center">
  <button class="my-auto h-min ml-sm" on:click={search}>
    <Search color="white" />
  </button>
  <input
    type="text"
    class=" text-sm font-sans text-md relative z-3 my-auto bg-white bg-opacity-0 placeholder-white focus:outline-none outline-none text-white ml-sm w-full"
    class:text-md={isBig}
    class:filter-shadow={isAtHome}
    placeholder={Place_holder}
    bind:value={element}
    on:keydown={handleKeydown} />
</div>

<style>
  input:focus::placeholder {
    color: transparent;
  }
</style>
