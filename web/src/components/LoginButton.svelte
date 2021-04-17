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
</script>

{#if $isAuthenticated}
  <Auth0LogoutButton class="w-full h-full">
    <span class="mx-auto my-auto text-sm {text[theme]} {filterShadow[theme]}">
      Ieși din cont
    </span>
  </Auth0LogoutButton>
{:else}
  <Auth0LoginButton class="w-full h-full" preserveRoute={true}>
    <span class="mx-auto my-auto text-sm {text[theme]} {filterShadow[theme]}">
      Intră în cont
    </span>
  </Auth0LoginButton>
{/if}
