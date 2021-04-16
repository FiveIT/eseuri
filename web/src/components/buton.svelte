<script lang="ts">
  import Link from './link.svelte'
  /**
   * The location to navigate to
   * @type {string}
   */
  export let link: string
  export let alive: boolean
  export let disable: boolean
  /**
   * Toggle this if the button should be white
   */
  export let white = false
</script>

{#if disable}
  <div
    class:text-white={white}
    class:text-black={!white}
    class:filter-shadow={white}
    class="w-full h-full flex justify-center items-center font-sans no-underline outline-none text-sm select-none ">
    <slot />
  </div>
{:else}
  <Link bind:alive href={link}>
    <div
      class:text-white={white}
      class:text-black={!white}
      class:filter-shadow={white}
      class="w-full h-full flex justify-center items-center font-sans no-underline text-sm outline">
      <slot />
    </div>
  </Link>
{/if}
