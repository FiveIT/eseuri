<script lang="ts">
  import LayoutContext from './LayoutContext.svelte'
  import Association from './Association.svelte'
  import Associate from 'svelte-material-icons/AccountPlus.svelte'
  import { px } from '$/lib/util'

  let size: string
  $: {
    size = px(3)
  }
  let show: boolean
  show = false
</script>

<LayoutContext>
  <button
    class="rounded border border-3px text-white h-full text-center mt-sm w-full flex flex-col items-center align-middle"
    on:click={() => (show = true)}>
    <div class="my-auto">
      <div class="mx-auto w-min">
        <Associate {size} />
      </div>
      <div class="text-center font-sans">Asociază-te</div>
    </div></button>
</LayoutContext>
{#if show}
  <Association bind:show />
{/if}
