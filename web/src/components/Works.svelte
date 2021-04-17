<script lang="ts">
  import type { Work } from '$/types'

  import W from './Work.svelte'

  export let works: Work[] = []
</script>

<div
  class="grid w-full h-full grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm">
  {#each works as work}
    <W {work} />
  {/each}
</div>
