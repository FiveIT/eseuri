<script context="module" lang="ts">
  import type { WorkSummary } from '$/lib'
  import type { UnrevisedWork } from '$/graphql/queries'

  type Input = WorkSummary[] | UnrevisedWork[] | undefined

  function isWorkSummaryArray(works: NonNullable<Input>): works is WorkSummary[] {
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
    {#if !works?.length}
      <p
        class="col-start-2 place-self-center text-center text-md font-sans antialiased {placeholderText[
          theme
        ]} {filterShadow[theme]}">
        Liber!<br />Nicio lucrare.
      </p>
    {:else if isWorkSummaryArray(works)}
      {#each works as work (work.url)}
        <W {work} />
      {/each}
    {:else}
      {#each works as work (work.id)}
        <UW {work} />
      {/each}
    {/if}
  </div>
</LayoutContext>
