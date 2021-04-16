<script>
  import Orange from '$/components/blob/Orange.svelte'
  import Red from '$/components/blob/Red.svelte'
  import Blue from '$/components/blob/Blue.svelte'
</script>

<div class="min-h-full">
  <div class="fixed bg-white w-full h-full -z-1000 blur" />
  <Orange />
  <Red />
  <Blue />
  <slot />
</div>
