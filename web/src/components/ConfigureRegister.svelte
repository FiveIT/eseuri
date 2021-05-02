<script lang="ts">
  import LayoutContext from './LayoutContext.svelte'
  import { text, border, filterShadow } from '$/theme'
  let success: boolean
  function handleclick() {
    success = true
  }
</script>

<LayoutContext let:theme>
  <button
    class="h-full w-configureloginwidth ml-columnwidth  rounded bg-blue bg-neongreen bg-red border-neongreen border-red border-white {border
      .size[theme]} {text[theme]} {filterShadow[theme]}"
    class:bg-blue={success == null}
    class:bg-red={success == false}
    class:bg-neongreen={success}
    class:border-white={success == null}
    class:border-neongreen={success}
    class:border-red={success == false}
    on:click={handleclick}>
    {#if success == null}
      Înregistrează-te
    {:else if success == true}
      Actualizat cu succes!
    {:else}
      Actualizare eșuată.
    {/if}
  </button>
</LayoutContext>
