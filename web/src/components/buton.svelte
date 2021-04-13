<script lang="ts">
  import Link from './link.svelte'
  /**
   * The location to navigate to
   * @type {string}
   */
  export let link: string
  export let alive: boolean
  /**
   * Toggle this if the button should be white
   */
  export let white = false
</script>

<Link bind:alive href={link}>
  <div
    class:text-white={white}
    class:text-black={!white}
    class:filter-shadow={white}
    class="w-full h-full flex justify-center items-center font-sans no-underline outline-none text-center ">
    <slot />
  </div>
</Link>
