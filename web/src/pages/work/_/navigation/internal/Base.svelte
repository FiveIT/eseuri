<script lang="ts">
  export let icon: any
</script>

<button on:click class="h-min sticky top-1/2 flex justify-center items-center">
  <svelte:component this={icon} size="4rem" color="var(--gray-light)" />
</button>

<style>
  button {
    will-change: transform;
  }
</style>
