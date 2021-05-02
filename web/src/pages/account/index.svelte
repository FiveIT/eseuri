<script lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import { store as window } from '$/components/Window.svelte'
  import type { BlobPropsInput, WorkType } from '$/types'
  import SlimNav from '$/components/SlimNav.svelte'
  import Configure from '$/components/Configure.svelte'

  let orangeBlobProps: BlobPropsInput = { scale: 1.8 }
  $: orangeBlobProps = {
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    rotate: 180,
    scale: 6,
    x: $window.width - red.width * 3,
    y: $window.height - 1500,
    zIndex: -2,
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
  <Configure />
  <SlimNav />
  <div
    class="row-start-4 row-span-1 col-start-1 col-span-2 my-auto text-white text-md font-sans">
    Contul meu
  </div>
  <div
    class="row-start-4 row-span-1 col-start-3 col-span-1 my-auto text-center text-white text-sm font-sans">
    Lucrări
  </div>
  <div
    class="row-start-4 row-span-1 col-start-4 col-span-1 my-auto text-center text-white text-sm font-sans">
    Marcaje
  </div>
  <div
    class="row-start-4 row-span-1 col-start-5 col-span-1 my-auto text-center text-white text-sm font-sans">
    Profesori
  </div>
  <div
    class="row-start-4 row-span-1 col-start-6 col-span-1 my-auto text-center text-white text-sm font-sans">
    Configurare/<wbr />Ieșire din cont
  </div>
  <hr class="text-white col-start-1 col-span-6 border-3px row-start-5 shadow" />
</Layout>
