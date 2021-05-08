<script context="module" lang="ts">
  import type { WorkSummary } from '$/lib'
  import type { UnrevisedWork } from '$/graphql/queries'

  type Input = WorkSummary[] | UnrevisedWork[] | undefined

  function isWorkSummaryArray(works: Input): works is WorkSummary[] {
    if (!works || !works.length) {
      return false
    }

    return 'url' in works[0]
  }
</script>

<script lang="ts">
  import { LayoutContext, Work as W, UnrevisedWork as UW } from '.'

  import { placeholderText, filterShadow } from '$/lib'

  export let works: Input
</script>

<LayoutContext let:theme>
  <div
    class="grid w-full h-full grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm col-start-1 col-end-7">
    {#if isWorkSummaryArray(works)}
      {#each works as work}
        <W {work} />
      {/each}
    {:else if works?.length}
      {#each works as work}
        <UW {work} />
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
