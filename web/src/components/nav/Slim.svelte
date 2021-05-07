<script>
  import Logo from './Logo.svelte'
  import { Forgery, Teachers, Login, Upload, Search } from './buttons'

  export let logoOnly = false
</script>

{#if logoOnly}
  <nav class="w-full z-10 col-span-6 row-span-2">
    <Logo on:navigate />
  </nav>
{:else}
  <nav class="w-full col-span-6 row-span-2">
    <div class="flex w-full z-10">
      <Logo on:navigate />
      <div class="ml-auto grid grid-flow-col gap-x-md auto-cols-layout">
        <span />
        <Search on:navigate />
        <Forgery on:navigate />
        <Teachers on:navigate />
        <Login />
      </div>
    </div>
    <div class="ml-auto w-min mr-1.4em">
      <Upload on:navigate />
    </div>
  </nav>
{/if}
