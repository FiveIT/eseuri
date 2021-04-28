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
  import { store as window } from '$/components/Window.svelte'
  import Works from '$/components/Works.svelte'
  import type { BlobPropsInput, WorkType } from '$/types'
  import { metatags } from '@roxi/routify'
  import { WORK_SUMMARIES } from '$/graphql/queries'
  import type { WorkSummaries, Data, Vars } from '$/graphql/types'
  import { operationStore, subscription } from '@urql/svelte'

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

  const content = operationStore<Data<WorkSummaries>, Vars<WorkSummaries>>(
    WORK_SUMMARIES,
    { type }
  )

  subscription(content, (_, newData) => newData)

  $: $content.variables!.type = type
</script>

<Layout
  {orangeBlobProps}
  {redBlobProps}
  {blueBlobProps}
  transition={{ y: 1000 }}>
  <div
    class="row-start-1 row-span-1 col-start-1  col-span-1 my-auto select-none">
    <Logo />
  </div>
  <div class=" row-start-1 row-span-1 col-start-3 col-end-6 text-sm my-auto">
    <Search />
  </div>
  <div class="w-full h-full row-start-1 row-span-1 col-start-6 col-span-1">
    <LoginButton theme="white" />
  </div>
  <div class="col-start-4 col-end-5 row-start-2 w-full h-full text-sm my-auto ">
    <Buton disable theme="white">Plagiat</Buton>
  </div>
  <div class="col-start-5 col-end-6 row-start-2 w-full h-full text-sm my-auto">
    <Buton disable theme="white">Profesori</Buton>
  </div>
  <div class="col-span-1 col-start-6 row-span-1 row-start-3 place-self-center">
    <UploadButton />
  </div>
  <TypeSelector bind:type rowStart={4} colStart={3} />
  <Works works={$content.data?.work_summaries} />
</Layout>
