<script lang="ts">
  import {
    Auth0LoginButton,
    Auth0LogoutButton,
    isAuthenticated,
  } from '@tmaxmax/svelte-auth0'
  import type { Theme } from '$/lib/types'
  import { text, filterShadow } from '$/lib/theme'
  import { getLayout } from './Layout.svelte'

  const { theme: themeStore } = getLayout()

  export let theme: Theme = $themeStore

  $: auth = $isAuthenticated
</script>

<svelte:component
  this={auth ? Auth0LogoutButton : Auth0LoginButton}
  class="w-full h-full font-sans text-sm antialiased {text[
    theme
  ]} {filterShadow[theme]}"
  preserveRoute={false}>
  {auth ? 'Ieși din cont' : 'Intră în cont'}
</svelte:component>
