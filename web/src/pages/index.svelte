<script lang="ts">
  import { blue, orange, red, Layout, NavBig, Spinner, window, notify } from '$/components'
  import TypeSelector from '$/components/TypeSelector.svelte'
  import Works from '$/components/Works.svelte'
  import type { BlobPropsInput, WorkType } from '$/lib/types'
  import { metatags } from '@roxi/routify'
  import { WORK_SUMMARIES } from '$/graphql/queries'
  import { operationStore, query } from '@urql/svelte'

  metatags.title = 'Acasă - Eseuri'

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    scale: 1.8,
    x: 0,
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    x: $window.width - red.width * 1.5,
    y: $window.height - red.height * 0.45,
    scale: 2,
    rotate: 180 + 26.7,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: ($window.width - blue.width * 0.8) / 2,
    y: -blue.height * 0.635 + $window.height * 0.17,
    scale: 1.5,
    rotate: 0,
  }

  let type: WorkType = 'essay'

  const content = query(operationStore(WORK_SUMMARIES, { type }, { requestPolicy: 'network-only' }))

  $: $content.variables!.type = type
  $: if ($content.error) {
    notify({
      status: 'error',
      message: 'Nu am putut obține lucrările.',
      explanation: `A apărut o eroare internă. Reîmprospătează pagina iar dacă apoi nu funcționează revino mai târziu, căci problema va fi în scurt timp rezolvată!`,
    })
  }
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} transition={{ y: 1000 }}>
  <NavBig />
  <TypeSelector bind:type rowStart={4} colStart={3} />
  {#if $content.data}
    <Works works={$content.data.work_summaries} />
  {:else if $content.fetching || $content.stale}
    <div class="row-start-5 col-span-6 flex justify-center">
      <Spinner />
    </div>
  {/if}
</Layout>
