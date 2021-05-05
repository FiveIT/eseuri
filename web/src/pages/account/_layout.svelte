<script lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import { store as window } from '$/components/Window.svelte'
  import type { BlobPropsInput } from '$/types'
  import SlimNav from '$/components/SlimNav.svelte'
  import NavLink from './_/NavLink.svelte'
  type Choosen = 'Lucrari' | 'Marcaje' | 'Profesori' | 'Configurare'

  let selected: Choosen
  selected = 'Lucrari'
  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    scale: 1.8,
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

  interface Route {
    href: string
    label: string
  }

  const routes: Route[] = [
    {
      href: '/works',
      label: 'Lucrări',
    },
    {
      href: '/bookmarks',
      label: 'Marcaje',
    },
    {
      href: '/associations',
      label: 'Asocieri',
    },
    {
      href: '/configure',
      label: 'Configurare/<wbr />Ieși din cont',
    },
  ]
</script>

<Layout
  theme="white"
  {orangeBlobProps}
  {redBlobProps}
  {blueBlobProps}
  transition={{ y: 1000 }}>
  <SlimNav />
  <div
    class="col-span-6 row-start-4 grid grid-cols-layout gap-x-md border-b-3px border-white filter-shadow items-center">
    <h2 class="text-md text-white font-sans antialiased col-span-2">
      Contul meu
    </h2>
    <ul
      class="col-start-3 col-span-4 grid grid-flow-col place-items-center gap-x-md auto-cols-layout">
      {#each routes as { href, label } (href)}
        <li class="w-full h-full text-center">
          <NavLink href="/account{href}">{@html label}</NavLink>
        </li>
      {/each}
    </ul>
  </div>
  <slot />
</Layout>
