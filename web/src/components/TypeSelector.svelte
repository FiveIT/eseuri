<script lang="ts">
  import type { WorkType } from '$/lib/types'
  import { workTypeTranslation } from '$/lib/content'
  import { text, filterShadow } from '$/lib/theme'

  import { getLayout } from './Layout.svelte'

  const { theme: themeStore } = getLayout()

  export let theme = $themeStore
  export let type = 'essay'
  export let colStart: number
  export let rowStart: number

  const types: WorkType[] = ['essay', 'characterization']
  const translate = (type: WorkType) => workTypeTranslation.ro[type].inarticulate.plural
</script>

{#each types as t, i}
  <div class="col-start-{colStart + i} col-span-1 row-start-{rowStart} w-full h-full m-auto my-auto {filterShadow[theme]}">
    <button
      class="w-full h-full font-sans text-sm antialiased capitalize {text[theme]}"
      class:underline={type === t}
      on:click={() => (type = t)}>{translate(t)}</button>
  </div>
{/each}
