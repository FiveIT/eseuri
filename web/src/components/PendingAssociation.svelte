<script lang="ts">
  import LayoutContext from './LayoutContext.svelte'
  import { px } from '$/util'
  import { text, border, filterShadow, background } from '$/theme'
  let size: string
  $: {
    size = px(3)
  }
  let show: boolean
  show = false
</script>

<LayoutContext let:theme>
  <div
    class="grid grid-rows-2 grid-cols-2 rounded border border-3px text-white h-full text-center mt-sm w-full wa {border
      .size[theme]} ">
    <div class="col-span-2 font-sans ">
      Asociere cu:<br />Ion Popescu
    </div>
    <button
      class="col-start-1 row-start-2 text-center border rounded bg-white text-black mx-md my-sm">
      Da
    </button>
    <button
      class="col-start-2 row-start-2 text-center border rounded bg-red text-black mx-md my-sm">
      Nu
    </button>
  </div>
</LayoutContext>

<style>
  .wa {
    background: rgba(0, 0, 0, 0.5);
  }
</style>
