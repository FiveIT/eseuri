<script lang="ts">
  import { LayoutContext } from '.'
  import { lucrari } from '$/content'
  import { text, filterShadow } from '$/lib'
  import LucrariModel from './LucrariModel.svelte'

  type Choosen = 'InLucru' | 'InAsteptare' | 'Aprobate' | 'Respinse' | 'InRevizuire'

  let selected: Choosen
  selected = 'InLucru'
  $: works = lucrari.filter(lucrari => lucrari.status === selected)
</script>

<LayoutContext let:theme>
  <div
    class=" z-10 {text[theme]} {filterShadow[
      theme
    ]}   col-start-1 col-span-6 row-start-5 row-span-6 grid grid-cols-6 grid-rows-6 gap-x-md gap-y-sm mt-sm ">
    <button
      class:underline={selected == 'InLucru'}
      class="col-start-1 row-start-2 w-full h-full "
      on:click={() => (selected = 'InLucru')}>În lucru</button>
    <button
      class:underline={selected == 'InAsteptare'}
      class="col-start-1 row-start-3 w-full h-full "
      on:click={() => (selected = 'InAsteptare')}>În așteptare</button>
    <button
      class:underline={selected == 'InRevizuire'}
      class="col-start-1 row-start-4 w-full h-full "
      on:click={() => (selected = 'InRevizuire')}>În revizuire acum</button>
    <button
      class:underline={selected == 'Aprobate'}
      class="col-start-1 row-start-5 w-full h-full "
      on:click={() => (selected = 'Aprobate')}>Aprobate</button>
    <button
      class:underline={selected == 'Respinse'}
      class="col-start-1 row-start-6 w-full h-full "
      on:click={() => (selected = 'Respinse')}>Respinse</button>
    <div class="col-start-2 row-start-1 my-auto text-center">Tip</div>
    <div class="col-start-3 col-span-2 row-start-1 my-auto text-center">Subiect</div>
    <div class="col-start-5 row-start-1 my-auto text-center">
      {#if selected === 'Aprobate'}
        Timpul<br /> Aprobarii
      {:else if selected === 'Respinse'}
        Timpul <br />Respingerii
      {:else}
        Ultima <br />Actualizare
      {/if}
    </div>
    <div class="col-start-6  row-start-1 my-auto text-center">Profesor Responsabil</div>
    <div
      class="col-start-2 col-span-5 row-start-2 row-span-full grid grid-cols-1 grid-rows-5 gap-y-sm ">
      {#each works as lucrare}
        <LucrariModel
          type={lucrare.type}
          teacher={lucrare.teacher}
          time={lucrare.time}
          subiect={lucrare.subject} />
      {/each}
    </div>
  </div></LayoutContext>
