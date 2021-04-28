<script lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import Search from '$/components/SearchBar.svelte'
  import SlimNav from '$/components/SlimNav.svelte'
  import { store as window } from '$/components/Window.svelte'
  import Works from '$/components/Works.svelte'
  import type { BlobPropsInput, WorkType } from '$/types'
  import { isWorkType } from '$/types'
  import { afterPageLoad, goto, params } from '@roxi/routify'
  import { operationStore, query } from '@urql/svelte'
  import { SEARCH_WORK_SUMMARIES } from '$/graphql/queries'
  import type { SearchWorkSummaries, Data, Vars } from '$/graphql/types'
  import TypeSelector from '$/components/TypeSelector.svelte'
  import debounce from 'lodash.debounce'

  let q: string = $params.query?.trim() || ''
  let type: WorkType = isWorkType($params.type) ? $params.type : 'essay'
  let focusInput = () => {}

  const content = operationStore<
    Data<SearchWorkSummaries>,
    Vars<SearchWorkSummaries>
  >(SEARCH_WORK_SUMMARIES, {
    query: `${q}%` as const,
    type,
  })

  query(content)

  $: $content.variables = {
    query: `${q}%` as const,
    type,
  }

  $: works = $content.data?.work_summaries
    .map(value => ({
      value,
      matchesOnName: +value.name
        .toLocaleLowerCase('ro-RO')
        .startsWith(q.toLocaleLowerCase('ro-RO')),
    }))
    .sort((a, b) => b.matchesOnName - a.matchesOnName)
    .map(v => v.value)

  const navigate = debounce((query: string) => {
    if (query === '') {
      $goto('/search', { type }, { redirect: true })
    } else {
      $goto('/search', { query, type })
    }
  }, 1000)

  $: navigate(q.trim())

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
    scale: 13,
  }

  let once = false
  $afterPageLoad(() => {
    if (!once) {
      focusInput()
      once = true
    }
  })
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
    <Search bind:query={q} bind:type bind:focusInput />
  </div>
  <TypeSelector bind:type rowStart={3} colStart={5} />
  <Works {works} />
</Layout>
