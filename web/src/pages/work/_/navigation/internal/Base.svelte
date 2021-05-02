<script lang="ts">
  export let icon: any
  export let disabled: boolean = false
</script>

<button
  on:click
  class="h-min sticky top-1/2 flex justify-center items-center select-none transition duration-300 disabled:(opacity-0 pointer-events-none)"
  {disabled}>
  <svelte:component this={icon} size="4rem" color="var(--gray-light)" />
</button>

<style>
  button {
    will-change: transform;
  }
</style>
