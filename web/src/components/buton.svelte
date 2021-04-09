<script lang="ts">
  import Link from './Link.svelte'
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

<div
  class:text-white={white}
  class:text-black={!white}
  class="no-underline outline-none text-center mt-auto mb-auto filter-shadow">
  <Link bind:alive href={link}>
    <slot />
  </Link>
</div>
