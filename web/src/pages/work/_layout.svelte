<script lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import { store as window } from '$/components/Window.svelte'
  import type { BlobPropsInput } from '$/lib/types'
  import SlimNav from '$/components/SlimNav.svelte'

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    scale: 1.8,
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    rotate: 47,
    scale: 2,
    x: $window.width + red.width / 2.5,
    y: $window.height + 40,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: ($window.width - blue.width * 1) / 2,
    y: -blue.height * 1 - $window.height * 0.1,
    scale: 1.4,
  }
</script>

<Layout
  {orangeBlobProps}
  {redBlobProps}
  {blueBlobProps}
  transition={{ y: 1000 }}>
  <SlimNav />
  <slot />
</Layout>
