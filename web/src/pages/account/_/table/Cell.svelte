<script lang="ts">
  export let cols = 1
</script>

<span
  role="cell"
  class="w-full h-full flex items-center justify-center text-center col-span-{cols} select-none leading-none">
  <slot />
</span>
