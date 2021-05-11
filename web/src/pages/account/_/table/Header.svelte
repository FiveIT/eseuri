<script lang="ts">
  export let cols = 1
</script>

<span role="columnheader" class="place-self-center text-center col-span-{cols} select-none">
  <slot />
</span>
