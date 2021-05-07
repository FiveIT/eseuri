<script lang="ts">
  import {
    blue,
    orange,
    red,
    Layout,
    SearchBar,
    NavSlim,
    window,
    Spinner,
    notify,
  } from '$/components'

  import Works from '$/components/Works.svelte'
  import TypeSelector from '$/components/TypeSelector.svelte'

  import type { BlobPropsInput, WorkType } from '$/lib'
  import { isWorkType } from '$/lib'
  import { SEARCH_WORK_SUMMARIES } from '$/graphql/queries'

  import { afterPageLoad, goto, params, metatags } from '@roxi/routify'
  import { operationStore, query } from '@urql/svelte'
  import debounce from 'lodash.debounce'

  let q: string = $params.query?.trim() || ''
  let type: WorkType = isWorkType($params.type) ? $params.type : 'essay'
  let focusInput = () => {}

  $: metatags.title = `${q ? `"${q}" - ` : ''}Căutare - Eseuri`

  const content = query(
    operationStore(SEARCH_WORK_SUMMARIES, {
      query: q,
      type,
    })
  )

  $: $content.variables = {
    query: q,
    type,
  }

  $: if ($content.error) {
    notify({
      status: 'error',
      message: 'Căutarea a eșuat',
      explanation: `Este o eroare internă, revino mai târziu - va fi rezolvată până atunci!`,
    })
  }

  const navigate = debounce(
    (query: string, type: string) => {
      if (query === '') {
        $goto('/search', { type }, { redirect: true })
      } else {
        $goto('/search', { query, type })
      }
    },
    1000,
    { leading: true }
  )

  $: navigate(q.trim(), type)

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
    scale: 15,
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
  afterMount={() => document.body.classList.add('bg-blue')}
  beforeDestroy={() => document.body.classList.remove('bg-blue')}>
  <NavSlim />
  <div class="col-start-1 row-span-1 row-start-3 col-end-4 my-auto">
    <SearchBar bind:query={q} bind:type bind:focusInput />
  </div>
  <TypeSelector bind:type rowStart={3} colStart={5} />
  {#if $content.data}
    <Works works={$content.data.find_work_summaries} />
  {:else if $content.fetching || $content.stale}
    <div class="row-start-4 col-span-6 flex justify-center">
      <Spinner />
    </div>
  {/if}
</Layout>
