<script lang="ts">
  import { goto } from '@roxi/routify'
  import { tick } from 'svelte'
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

<div class="flex flex-row">
  <div class="relative my-auto ml-sm">
    <button class=" w-full" on:click={search}>
      <svg
        width="16"
        height="16"
        viewBox="0 0 16 16"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        class="my-auto">
        <path
          d="M12.5 11H11.71L11.43 10.73C12.41 9.59 13 8.11 13 6.5C13 2.91 10.09 0 6.5 0C2.91 0 0 2.91 0 6.5C0 10.09 2.91 13 6.5 13C8.11 13 9.59 12.41 10.73 11.43L11 11.71V12.5L16 17.49L17.49 16L12.5 11ZM6.5 11C4.01 11 2 8.99 2 6.5C2 4.01 4.01 2 6.5 2C8.99 2 11 4.01 11 6.5C11 8.99 8.99 11 6.5 11Z"
          fill="#FCFAF9" />
      </svg>
    </button>
  </div>
  <input
    type="text"
    class=" text-sm font-sans text-md relative z-3 my-auto  bg-white bg-opacity-0 placeholder-white focus:outline-none outline-none text-white ml-sm w-full"
    class:text-md={isBig}
    placeholder={Place_holder}
    bind:value={element}
    on:keydown={handleKeydown} />
</div>

<style>
  input:focus::placeholder {
    color: transparent;
  }
</style>
