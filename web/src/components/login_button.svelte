<script>
  import {
    Auth0LoginButton,
    Auth0LogoutButton,
    isAuthenticated,
    isLoading,
  } from '@tmaxmax/svelte-auth0'
  export let white = false
  $: console.log($isAuthenticated)
  $: console.log($isLoading)
</script>

{#if $isAuthenticated}
  <Auth0LogoutButton>
    <span class=" mx-auto" class:text-white={white} class:text-black={!white}>
      Ieși din cont
    </span>
  </Auth0LogoutButton>
{:else}
  <Auth0LoginButton preserveRoute={true}>
    <span class=" mx-auto " class:text-white={white} class:text-black={!white}>
      Intră în cont
    </span>
  </Auth0LoginButton>
{/if}
