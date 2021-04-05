<script>
  import { url, isActive } from '@roxi/routify'
  import { store as window } from '$/components/Window.svelte'
  import Blue from '$/components/blob/Blue.svelte'
  import Orange from '$/components/blob/Orange.svelte'
  import Red from '$/components/blob/Red.svelte'
</script>

<div class="w-full h-full relative">
  {#if $window.width > 530}
    <div class="fixed w-full h-full bg-white -z-1000" />
    <Orange />
    <Red />
    <Blue />
  {:else}
    <div
      class="bg fixed w-full h-full from-orange to-blue via-white bg-gradient-to-tl -z-1000" />
  {/if}

  <main class="flex flex-col items-center w-full min-h-full">
    <a href={$url($isActive('./index') ? './about' : './')}
      ><h1
        class="font-serif text-xl subpixel-antialiasing font-bold select-none m-0">
        Cat facts<span class="text-orange">.</span>
      </h1></a>
    <slot />
  </main>
</div>

<style>
  :global(html, body) {
    font-size: 18px;
    @apply h-full;
  }

  main {
    padding: 10vmin;
  }

  .bg {
    filter: blur(100px);
  }
</style>
