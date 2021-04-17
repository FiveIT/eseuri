<script lang="ts">
  import { metatags } from '@roxi/routify'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'
  import Buton from '$/components/NavButton.svelte'
  import Search from '$/components/SearchBar.svelte'
  import UploadButton from '$/components/UploadButton.svelte'
  import Logo from '$/components/Logo.svelte'
  import LoginButton from '$/components/LoginButton.svelte'
  import Layout from '$/components/Layout.svelte'
  import Works from '$/components/Works.svelte'

  import type { BlobPropsInput, WorkType } from '$/types'

  import content from '$/content'

  metatags.title = 'Eseuri'

  let orangeBlobProps: BlobPropsInput = { scale: 1.8 }
  $: orangeBlobProps = {
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput = {
    scale: 2,
    rotate: 180 + 26.7,
    flip: { x: 1, y: 0 },
  }
  $: redBlobProps = {
    x: $window.width - red.width * 1.5,
    y: $window.height - red.height * 0.45,
  }

  let blueBlobProps: BlobPropsInput = { scale: 1.5 }
  $: blueBlobProps = {
    x: ($window.width - blue.width * 0.8) / 2,
    y: -blue.height * 0.635 + $window.height * 0.17,
  }

  let type: WorkType = 'essay'
  $: works = content.filter(work => work.type === type)
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps}>
  <div
    class="row-start-1 row-span-1 col-start-1  col-span-1 my-auto select-none">
    <Logo />
  </div>
  <div class=" row-start-1 row-span-1 col-start-3 col-end-6 text-sm my-auto">
    <Search isAtHome={true} isBig={false} />
  </div>
  <div class="w-full h-full row-start-1 row-span-1 col-start-6 col-span-1">
    <LoginButton theme="white" />
  </div>
  <div class="col-start-4 col-end-5 row-start-2 w-full h-full text-sm my-auto ">
    <Buton enable={false}>Plagiat</Buton>
  </div>
  <div class="col-start-5 col-end-6 row-start-2 w-full h-full text-sm my-auto">
    <Buton enable={false}>Profesori</Buton>
  </div>
  <div class="col-span-1 col-start-6 row-span-1 row-start-3 mx-auto">
    <UploadButton />
  </div>
  <div class=" col-start-3 col-end-4 row-start-4 w-full h-full m-auto my-auto ">
    <button
      class=" w-full h-full  bg-white bg-opacity-0 font-sans text-sm "
      class:underline={type === 'essay'}
      on:click={() => (type = 'essay')}>Eseuri</button>
  </div>
  <div class="col-start-4 col-end-5 row-start-4 w-full h-full m-auto my-auto">
    <button
      class="bg-white w-full h-full bg-opacity-0 my-auto font-sans text-sm "
      class:underline={type === 'characterization'}
      on:click={() => (type = 'characterization')}>Caracterizari</button>
  </div>
  <Works {works} />
</Layout>
