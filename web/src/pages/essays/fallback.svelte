<script lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import Logo from '$/components/Logo.svelte'
  import UploadButton from '$/components/UploadButton.svelte'
  import { store as window } from '$/components/Window.svelte'
  import content from '$/content'
  import type { BlobPropsInput, WorkType } from '$/types'
  import { metatags } from '@roxi/routify'
  import SlimNav from '$/components/SlimNav.svelte'
  metatags.title = 'Eseuri'

  let orangeBlobProps: BlobPropsInput = { scale: 1.8 }
  $: orangeBlobProps = {
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    rotate: 47,
    scale: 2,
    x: $window.width - red.width * 2,
    y: $window.height + 40,
  }

  let blueBlobProps: BlobPropsInput = { scale: 1.4 }
  $: blueBlobProps = {
    x: ($window.width - blue.width * 1) / 2,
    y: -blue.height * 1 - $window.height * 0.1,
    scale: 1.4,
  }

  const paragraphs = [
    'Subiectul căutat de tine nu este la noi pe platformă.',
    'Dacă ai ajuns aici din greșeală, folosește bara de navigare pentru a ieși de aici.',
    'Dacă ai căutat intenționat acest subiect și crezi că ar trebui să existe pe platformă, <a class="underline" href="mailto:tmaxmax@outlook.com">scrie-ne un email!</a>',
  ]
</script>

<Layout
  {orangeBlobProps}
  {redBlobProps}
  {blueBlobProps}
  transition={{ y: 1000 }}>
  <SlimNav />
  <div class="flex flex-col col-start-2 col-span-4 text-center">
    <h2 class="font-serif text-title antialiased mb-md">
      Ups! Această lucrare nu există.
    </h2>
    {#each paragraphs as text}
      <p
        class="text-sm font-sans mt-sm antialiased leading-none mx-auto max-w-1/2">
        {@html text}
      </p>
    {/each}
  </div>
</Layout>
