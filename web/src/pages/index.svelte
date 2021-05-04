<script lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import LoginButton from '$/components/LoginButton.svelte'
  import Logo from '$/components/Logo.svelte'
  import Buton from '$/components/NavButton.svelte'
  import Search from '$/components/SearchBar.svelte'
  import UploadButton from '$/components/UploadButton.svelte'
  import TypeSelector from '$/components/TypeSelector.svelte'
  import Spinner from '$/components/Spinner.svelte'
  import { store as window } from '$/components/Window.svelte'
  import Works from '$/components/Works.svelte'
  import type { BlobPropsInput, WorkType } from '$/lib/types'
  import { metatags } from '@roxi/routify'
  import { WORK_SUMMARIES } from '$/graphql/queries'
  import { operationStore, query } from '@urql/svelte'
  import Notifications, { notify } from '$/components/Notifications.svelte'

  metatags.title = 'Eseuri'

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
  <Logo />
  <div class="col-start-3 col-end-6 my-auto">
    <Search />
  </div>
  <div class="col-start-6">
    <LoginButton theme="white" />
  </div>
  <div class="col-start-4 my-auto">
    <Buton disable theme="white">Plagiat</Buton>
  </div>
  <div class="col-start-5 my-auto">
    <Buton disable theme="white">Profesori</Buton>
  </div>
  <div class="col-start-6 row-start-3 place-self-center">
    <UploadButton />
  </div>
  <TypeSelector bind:type rowStart={4} colStart={3} />
  {#if $content.data}
    <Works works={$content.data.work_summaries} />
  {:else if $content.fetching || $content.stale}
    <div class="row-start-5 col-span-6 flex justify-center">
      <Spinner />
    </div>
  {/if}
  <Notifications />
</Layout>
