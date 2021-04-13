<script lang="ts">
  import Link from './link.svelte'
  export let name: string
  export let scriitor: string
  export let works: number
  export let alive: boolean
  export let white: boolean
  let size: string
  if (name.length > 26) size = 'prose'
  else size = 'md'
</script>

<Link bind:alive href={`/essays/${name}`}>
  {#if white}
    <div
      class="relative grid blur_white border-3 w-full h-full font-sans  "
      class:text-white={white}
      class:border-white={white}
      class:border-1={!white}
      class:border-black={!white}
      class:text-black={!white}>
      <h2 class=" text-{size} my-auto ml-sm font-sans">{name}</h2>
      <div class=" ml-sm " class:text-gray={!white} class:text-white={white}>
        {scriitor}
        <div>{works}</div>
      </div>
    </div>
  {:else}
    <div
      class="relative flex flex-col blur border-2 w-full h-full font-sans bg-white bg-opacity-50 "
      class:text-white={white}
      class:border-white={white}
      class:border-black={!white}
      class:text-black={!white}>
      <h2 class=" h-1/2 w-full text-{size} my-auto ml-sm font-sans  ">
        {name}
      </h2>
      <div
        class=" ml-sm text-gray-dark"
        class:text-black={!white}
        class:text-white={white}>
        {scriitor}
        <div>{works}</div>
      </div>
    </div>
  {/if}
</Link>

<style>
  .blur_white {
    filter: drop-shadow(2px 2px 5px rgba(0, 0, 0, 0.5));
    backdrop-filter: blur(100px);
    border-radius: 10px;
    row-gap: var(--l_gap_row);
    grid-template-rows: repeat(2, var(--l_row));
  }
  .blur {
    backdrop-filter: blur(100px);
    border-radius: 10px;
    row-gap: var(--l_gap_row);
    grid-template-rows: repeat(2, var(--l_row));
  }
</style>
