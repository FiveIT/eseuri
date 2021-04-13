<script>
  import Orange from '$/components/blob/Orange.svelte'
  import Red from '$/components/blob/Red.svelte'
  import Blue from '$/components/blob/Blue.svelte'
</script>

<div class="w-full h-full relative pb-lg">
  <div class="bg-white  bg fixed w-full h-full -z-1000 blur" />
  <Orange />
  <Red />
  <Blue />

  <main class=" relative flex flex-col items-center w-full min-h-full ">
    <slot />
  </main>
</div>

<style>
  :global(html, body) {
    font-size: 18px;
    height: 100%;
    overflow-x: hidden;
  }
</style>
