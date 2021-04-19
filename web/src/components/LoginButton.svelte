<script lang="ts">
  import {
    Auth0LoginButton,
    Auth0LogoutButton,
    isAuthenticated,
  } from '@tmaxmax/svelte-auth0'
  import { getContext } from 'svelte'

  import type { Theme } from '$/types'
  import { text, filterShadow } from '$/theme'

  import type { Context } from './Layout.svelte'
  import { contextKey } from './Layout.svelte'

  const { theme: themeStore } = getContext<Context>(contextKey)

  export let theme: Theme = $themeStore

  $: auth = $isAuthenticated
</script>

<svelte:component
  this={auth ? Auth0LogoutButton : Auth0LoginButton}
  class="w-full h-full font-sans text-sm antialiased {text[
    theme
  ]} {filterShadow[theme]}"
  preserveRoute={!auth}>
  {auth ? 'Ieși din cont' : 'Intră în cont'}
</svelte:component>
