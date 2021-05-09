<script>
  import { isAuthenticated } from '@tmaxmax/svelte-auth0'
  import Button from './Button.svelte'
</script>

{#if $isAuthenticated}
  <Button />
{/if}
