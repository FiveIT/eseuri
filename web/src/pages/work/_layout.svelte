<script lang="ts">
  import { blue, orange, red, Layout, window, NavSlim } from '$/components'
  import type { BlobPropsInput } from '$/lib'

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

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} transition={{ y: 1000 }}>
  <NavSlim />
  <slot />
</Layout>
