<script lang="ts">
  import { LayoutContext } from '.'
  import { text, border, filterShadow } from '$/lib/theme'
  let success: boolean | undefined
  function handleclick() {
    success = true
  }
</script>

<LayoutContext let:theme>
  <button
    class="h-full w-configure-login ml-col  rounded bg-blue bg-green-light bg-red border-green-light border-red border-white {border
      .size[theme]} {text[theme]} {filterShadow[theme]}"
    class:bg-blue={success == null}
    class:bg-red={!success}
    class:bg-green-light={success}
    class:border-white={success == null}
    class:border-green-light={success}
    class:border-red={!success}
    on:click={handleclick}>
    {#if success == null}
      Înregistrează-te
    {:else if success === true}
      Actualizat cu succes!
    {:else}
      Actualizare eșuată.
    {/if}
  </button>
</LayoutContext>
