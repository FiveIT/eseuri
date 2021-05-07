<script lang="ts">
  import type { WorkSummary } from '$/lib'

  import { LayoutContext } from '.'
  import W from './Work.svelte'

  import { placeholderText, filterShadow } from '$/lib'

  export let works: WorkSummary[] | undefined
</script>

<LayoutContext let:theme>
  <div
    class="grid w-full h-full grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm col-start-1 col-end-7">
    {#if works?.length}
      {#each works as work (work.name)}
        <W {work} />
      {/each}
    {:else}
      <p
        class="col-start-2 place-self-center text-center text-md font-sans antialiased {placeholderText[
          theme
        ]} {filterShadow[theme]}">
        Liber!<br />Nicio lucrare.
      </p>
    {/if}
  </div>
</LayoutContext>
