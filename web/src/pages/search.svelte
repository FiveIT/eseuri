<script lang="ts">
  import Layout from '$/components/Layout.svelte'
  import SlimNav from '$/components/SlimNav.svelte'
  import Search from '$/components/SearchBar.svelte'
  import Works from '$/components/Works.svelte'

  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'

  import type { BlobPropsInput, WorkType } from '$/types'

  import content from '$/content'
  import { workTypeTranslation } from '$/content'

  let query = ''
  let type: WorkType = 'essay'
  let workTypes: WorkType[] = ['essay', 'characterization']

  $: works = content.filter(
    ({ type: t, name: n }) =>
      t === type && n.toLowerCase().includes(query.toLowerCase())
  )

  let orangeBlobProps: BlobPropsInput = { scale: 1.8 }
  $: orangeBlobProps = {
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput = {
    scale: 2,
    x: $window.width + red.width * 0.6,
    y: $window.height - red.height * 0.45,
  }

  let blueBlobProps: BlobPropsInput = { scale: 17 }
  $: blueBlobProps = {
    x: ($window.width - blue.width * 0.8) / 2,
    y: -blue.height * 0.635 + $window.height * 0.17,
  }
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} theme="white">
  <SlimNav />
  <div class="col-start-1 row-span-1 row-start-3 col-end-4 my-auto ">
    <Search {query} isBig={true} isAtHome={false} />
  </div>
  {#each workTypes as t, i}
    <button
      class="bg-opacity-0 row-span-1 row-start-3 text-white col-start-{4 +
        i} col-span-1 text-sm filter-shadow capitalize"
      class:underline={type === t}
      on:click={() => (type = t)}
      >{workTypeTranslation.ro[t].inarticulate.plural}</button>
  {/each}
  <Works {works} />
</Layout>
