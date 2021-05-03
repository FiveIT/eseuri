<script lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import { store as window } from '$/components/Window.svelte'
  import type { BlobPropsInput } from '$/types'
  import SlimNav from '$/components/SlimNav.svelte'
  import Configure from '$/components/Configure.svelte'
  import Bookmark from '$/components/Bookmark.svelte'
  import Lucrari from '$/components/Lucrari.svelte'
  import Teachers from '$/components/Teachers.svelte'
  type Choosen = 'Lucrari' | 'Marcaje' | 'Profesori' | 'Configurare'

  let selected: Choosen
  selected = 'Configurare'
  let orangeBlobProps: BlobPropsInput = { scale: 1.8 }
  $: orangeBlobProps = {
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
    zIndex: -1,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    rotate: 180,
    scale: 6,
    x: $window.width - red.width * 3,
    y: $window.height - 1500,
    zIndex: -1,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    scale: 18,
    rotate: 45,
    x: $window.width - blue.width * 1,
    y: $window.height - 400,
    zIndex: -3,
  }
</script>

<Layout
  theme="white"
  {orangeBlobProps}
  {redBlobProps}
  {blueBlobProps}
  transition={{ y: 1000 }}>
  {#if selected == 'Configurare'}
    <Configure />
  {:else if selected == 'Lucrari'}
    <Lucrari />
  {:else if selected == 'Marcaje'}<Bookmark />{:else if selected == 'Profesori'}<Teachers />{/if}

  <SlimNav />
  <div
    class="bg-transparent row-start-4  row-span-1 col-start-1 col-span-2 my-auto text-white text-md font-sans">
    Contul meu
  </div>
  <button
    class="row-start-4 h-full row-span-1 col-start-3 col-span-1 my-auto text-center text-white text-sm font-sans"
    on:click={() => (selected = 'Lucrari')}>
    Lucrări
  </button>
  <button
    class="row-start-4 h-full row-span-1 col-start-4 col-span-1 my-auto text-center text-white text-sm font-sans"
    on:click={() => (selected = 'Marcaje')}>
    Marcaje
  </button>
  <button
    class="row-start-4 h-full row-span-1 col-start-5 col-span-1 my-auto text-center text-white text-sm font-sans"
    on:click={() => (selected = 'Profesori')}>
    Profesori
  </button>
  <button
    class="row-start-4 h-full row-span-1 col-start-6 col-span-1 my-auto text-center text-white text-sm font-sans"
    on:click={() => (selected = 'Configurare')}>
    Configurare/<wbr />Ieșire din cont
  </button>
  <hr class="text-white col-start-1 col-span-6 border-3px row-start-5 shadow" />
</Layout>
