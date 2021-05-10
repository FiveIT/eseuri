<script lang="ts">
  import { Auth0LoginButton, isAuthenticated, isLoading } from '@tmaxmax/svelte-auth0'
  import type { Theme } from '$/lib'
  import { text, filterShadow } from '$/lib'
  import { getLayout, NavButton } from '$/components'

  const { theme: themeStore } = getLayout()

  export let theme: Theme = $themeStore

  $: auth = $isAuthenticated
  $: label = auth ? 'Ieși din cont' : 'Intră în cont'
</script>

{#if $isAuthenticated}
  <NavButton
    href="/account"
    title="Manageriază-ți lucrările, marcajele și contul"
    hideIfDisabled
    {theme}>Contul meu</NavButton>
{:else if $isLoading}
  <div
    class="h-full font-sans {text[theme]} text-sm antialiased {filterShadow[
      theme
    ]} text-center flex items-center justify-center">
    Se încarcă...
  </div>
{:else}
  <div title={label} class="h-full">
    <Auth0LoginButton
      class="w-full h-full font-sans text-sm antialiased {text[theme]} {filterShadow[theme]}"
      preserveRoute={false}>{label}</Auth0LoginButton>
  </div>
{/if}
