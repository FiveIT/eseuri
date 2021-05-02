<script>
  import Logo from './Logo.svelte'
  import NavButton from './NavButton.svelte'
  import LoginButton from './LoginButton.svelte'
  import UploadButton from './UploadButton.svelte'

  export let logoOnly = false
</script>

{#if logoOnly}
  <nav class="w-full col-span-6 row-span-2">
    <Logo on:navigate />
  </nav>
{:else}
  <nav class="w-full col-span-6 row-span-2">
    <div class="flex w-full">
      <Logo on:navigate />
      <div class="ml-auto grid grid-flow-col gap-x-md auto-cols-layout">
        <span />
        <NavButton href="/search" hideIfDisabled on:navigate>Caută</NavButton>
        <NavButton disable on:navigate>Plagiat</NavButton>
        <NavButton disable on:navigate>Profesori</NavButton>
        <LoginButton />
      </div>
    </div>
    <div class="ml-auto w-min mr-1.4em">
      <UploadButton on:navigate />
    </div>
  </nav>
{/if}
