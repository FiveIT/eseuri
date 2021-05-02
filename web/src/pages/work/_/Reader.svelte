<script lang="ts">
  import { Next, Back, Bookmark } from '.'

  export let title: string
  export let content: string
  export let next: () => void
  export let prev: () => void
</script>

<div class="col-start-2 col-end-6 row-start-3 flex flex-col space-y-sm justify-between">
  <h2 class="text-title font-serif antialiased">
    {title}
  </h2>
  <div class="flex justify-between align-middle">
    <div class="w-min text-sm font-sans antialiased">Eseu</div>
    <div class="w-min"><Bookmark /></div>
  </div>
  <p class="text-prose font-serif antialiased">
    {content}
  </p>
</div>
<Back on:click={prev} />
<Next on:click={next} />
<div class="col-start-2">
  <Bookmark />
</div>
