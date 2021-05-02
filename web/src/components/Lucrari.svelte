<script lang="ts">
  import LayoutContext from './LayoutContext.svelte'

  import { text, filterShadow } from '$/theme'
</script>

<LayoutContext let:theme>
  <div
    class=" z-10 {text[theme]} {filterShadow[
      theme
    ]}   col-start-1 col-span-6 row-start-5 row-span-6 grid grid-cols-6 grid-rows-6 gap-x-md gap-y-sm mt-sm ">
    <button class="col-start-1 row-start-2 w-full h-full ">În lucru</button>
    <button class="col-start-1 row-start-3 w-full h-full ">În așteptare</button>
    <button class="col-start-1 row-start-4 w-full h-full "
      >În revizuire acum</button>
    <button class="col-start-1 row-start-5 w-full h-full ">Aprobate</button>
    <button class="col-start-1 row-start-6 w-full h-full ">Respinse</button>
  </div></LayoutContext>
