<script lang="ts">
  import { afterPageLoad, goto, params } from '@roxi/routify'

  import Layout from '$/components/Layout.svelte'
  import SlimNav from '$/components/SlimNav.svelte'
  import Search from '$/components/SearchBar.svelte'
  import Works from '$/components/Works.svelte'

  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'

  import type { BlobPropsInput, WorkType, Work } from '$/types'
  import { isWorkType } from '$/types'

  import content from '$/content'
  import { workTypeTranslation } from '$/content'

  let query: string = $params.query || ''
  let type: WorkType = isWorkType($params.type) ? $params.type : 'essay'
  let workTypes: WorkType[] = ['essay', 'characterization']
  let works: Work[]
  let focusInput = () => {}
  $: query = query.trimStart()

  const isValidEntry = (query: string, type: WorkType) => ({
    type: t,
    name: n,
    creator: c,
  }: Work) => {
    return (
      t === type &&
      [n, c].some(v => v.toLowerCase().includes(query.toLowerCase()))
    )
  }

  $: works = content.filter(isValidEntry(query, type))

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
    scale: 1.8,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    scale: 2,
    x: $window.width + red.width * 0.6,
    y: $window.height - red.height * 0.45,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: ($window.width - blue.width * 0.8) / 2,
    y: -blue.height * 0.635 + $window.height * 0.17,
    scale: 17,
  }

  $afterPageLoad(() => focusInput())
</script>

<Layout
  {orangeBlobProps}
  {redBlobProps}
  {blueBlobProps}
  theme="white"
  afterMount={() => (document.body.style.backgroundColor = 'var(--blue)')}
  beforeDestroy={() => (document.body.style.backgroundColor = '')}>
  <SlimNav />
  <div class="col-start-1 row-span-1 row-start-3 col-end-4 my-auto">
    <Search bind:query bind:type bind:focusInput />
  </div>
  {#each workTypes as t, i}
    <button
      class="bg-opacity-0 row-span-1 row-start-3 text-white col-start-{5 +
        i} col-span-1 text-sm filter-shadow capitalize"
      class:underline={type === t}
      on:click={() => ((type = t), $goto('/search', { query, type }))}
      >{workTypeTranslation.ro[t].inarticulate.plural}</button>
  {/each}
  <Works {works} />
</Layout>
