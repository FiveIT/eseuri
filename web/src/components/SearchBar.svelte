<script lang="ts">
  import Search from 'svelte-material-icons/Magnify.svelte'
  export let query: string = ''

  export let isBig = false
  export let isAtHome = false
</script>

<div class="flex flex-row items-center">
  <button class="my-auto h-min ml-sm">
    <Search color="white" />
  </button>
  <input
    type="text"
    class="font-sans text-md subpixel-antialiased my-auto bg-white bg-opacity-0 placeholder-white text-white ml-sm w-full"
    class:text-md={isBig}
    class:filter-shadow={isAtHome}
    class:filter-shadow-soft={!isAtHome}
    placeholder="Caută titluri sau personaje"
    bind:value={query} />
</div>

<style>
  input:focus::placeholder {
    color: transparent;
  }
</style>
