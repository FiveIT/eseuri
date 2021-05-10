<script context="module" lang="ts">
  interface Route {
    href: string
    label: string
    title: string
  }

  const routes: Route[] = [
    {
      href: 'works',
      label: 'Lucrări',
      title: 'Vezi stadiul lucrărilor tale încărcate.',
    },
    {
      href: 'bookmarks',
      label: 'Marcaje',
      title: 'Accesează-ți lucrările salvate.',
    },
    {
      href: 'associations',
      label: 'Asocieri',
      title: 'Urmărește stadiul asocierilor tale, răspunde la alte asocieri sau inițiază tu una.',
    },
    {
      href: 'configure',
      label: 'Configurare/<wbr />Ieși din cont',
      title:
        'Actualizează-ți datele, cere rolul de profesor, deconectează-te sau șterge-ți contul.',
    },
  ]

  const theme = 'white'
</script>

<script lang="ts">
  import { blue, orange, red, Layout, window, NavSlim, NavButton, Allow } from '$/components'
  import type { BlobPropsInput } from '$/components'
  import { filterShadow, text, background, border } from '$/lib'

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: ($window.width - blue.width * 0.8) / 2,
    y: -blue.height * 0.635 + $window.height * 0.17,
    scale: 13,
  }

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
    scale: 1.8,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    rotate: 180,
    scale: 0,
    x: $window.width - red.width * 3,
    y: $window.height - 1500,
    zIndex: 0,
  }
</script>

<Allow authenticated redirect="/">
  <Layout
    {theme}
    {blueBlobProps}
    {orangeBlobProps}
    {redBlobProps}
    transition={{ y: 1000 }}
    afterMount={() => document.body.classList.add(background[theme])}
    beforeDestroy={() => document.body.classList.remove(background[theme])}>
    <NavSlim />
    <div
      class="col-span-6 row-start-4 grid grid-cols-layout gap-x-md {border.color[theme]} {border.b[
        theme
      ]} items-center sticky top-0 bg-blue z-1">
      <h1
        class="col-span-2 text-md {text[theme]} font-sans antialiased select-none {filterShadow[
          theme
        ]}">
        Contul meu
      </h1>
      {#each routes as { href, label, title }}
        <div class="h-full">
          <NavButton href="/account/{href}" directGoto disable={false} {title} let:selected>
            <span class="text-center" class:underline={selected}>{@html label}</span>
          </NavButton>
        </div>
      {/each}
    </div>
    <div class="row-start-5 col-span-full grid grid-cols-6 gap-x-md gap-y-sm auto-rows-layout">
      <slot />
    </div>
  </Layout>
</Allow>
