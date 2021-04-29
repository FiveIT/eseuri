<script lang="ts" context="module">
  export const contextKey = {}

  interface Context {
    file: File | null
  }

  export type { Context }
</script>

<script lang="ts">
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import LayoutContext from '$/components/LayoutContext.svelte'
  import { go } from '$/components/Link.svelte'
  import Logo from '$/components/Logo.svelte'
  import UploadVariantPlaceholder from '$/components/UploadVariantPlaceholder.svelte'
  import { store as window } from '$/components/Window.svelte'
  import type { BlobPropsInput } from '$/lib/types'
  import { px } from '$/lib/util'
  import { goto } from '@roxi/routify'
  import { getContext } from 'svelte'
  import Allow, { AUTHENTICATED, REGISTERED } from '$/components/Allow.svelte'
  import Docs from 'svelte-material-icons/FileDocumentBoxMultiple.svelte'
  import GoogleDocs from 'svelte-material-icons/FileDocumentOutline.svelte'
  import Doodle from 'svelte-material-icons/Gesture.svelte'
  import ScrieAici from 'svelte-material-icons/TextSubject.svelte'

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    x: 10,
    y: $window.height - orange.height - 20,
    scale: 1.8,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    x: $window.width - red.width * 1,
    y: 0,
    scale: 2,
    rotate: 0,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: $window.width * 0.65,
    y: $window.height * 0.9,
    scale: 1.5,
  }

  let input: HTMLInputElement
  const ctx = getContext<Context>(contextKey)
</script>

<Allow when={AUTHENTICATED | REGISTERED} redirect="/">
  <Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} center>
    <LayoutContext let:alive>
      <div
        class="blur row-span-6 col-span-2 border -mt-sm -ml-md rounded white-bg bg-opacity-50 grid auto-rows-1fr grid-flow-row px-md py-sm gap-y-sm text-sm font-sans antialiased">
        <h2 class="m-auto">Publică o lucrare</h2>
        <UploadVariantPlaceholder icon={ScrieAici} fg="black" bg="white" border>
          Scrie-o aici
        </UploadVariantPlaceholder>
        <label
          class="flex items-center p-sm rounded bg-blue text-white justify-between cursor-pointer focus-within:outline-solid-black select-none">
          Încarcă un document
          <Docs color="var(--white)" size={px(1.5)} />
          <input
            name="file"
            type="file"
            accept=".txt,.doc,.docx,.odt,.rtf"
            class="opacity-0 w-0 h-0 absolute"
            on:change={() => {
              if (!input.files) {
                return
              }
              ctx.file = input.files[0]
              go('/upload_configure', alive, $goto)
            }}
            bind:this={input} />
        </label>
        <UploadVariantPlaceholder icon={GoogleDocs} bg="google-docs">
          Încarcă din Google Docs
        </UploadVariantPlaceholder>
        <h3 class="m-auto">Ai scris de mână?</h3>
        <UploadVariantPlaceholder icon={Doodle} bg="red">
          Încarcă imagini/PDF
        </UploadVariantPlaceholder>
      </div>
      <div class="row-start-3 row-span-2 col-start-4 col-span-2">
        <Logo big={true} />
      </div>
      <h3
        class="row-start-5 row-span-1 col-start-4 col-end-6 text-sm font-sans text-sm antialiased">
        Perfecționează-ți-le cu cea mai extinsă colecție din România!
      </h3>
    </LayoutContext>
  </Layout>
</Allow>
