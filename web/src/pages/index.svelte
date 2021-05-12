<script lang="ts">
  import { blue, orange, red, Layout, NavBig, window } from '$/components'
  import Spinner from './_/Spinner.svelte'
  import UserMenu from './_/User.svelte'
  import TeacherMenu from './_/Teacher.svelte'
  import { status } from '$/lib'
  import type { BlobPropsInput } from '$/lib'

  import { metatags } from '@roxi/routify'
  import { isAuthenticated, isLoading } from '@tmaxmax/svelte-auth0'

  metatags.title = 'Acasă - Eseuri'

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
    rotate: 0,
  }

</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} transition={{ y: 1000 }}>
  <NavBig />
  {#if $isLoading}
    <Spinner />
  {:else if !$isAuthenticated}
    <UserMenu />
  {:else if $status}
    <TeacherMenu id={$status.id} />
  {/if}
</Layout>
