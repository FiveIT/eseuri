<script lang="ts">
  import LayoutContext from './LayoutContext.svelte'
  import Delete from './DeleteAccount.svelte'
  import Become from './BecomeATeacher.svelte'
  import { text, border, filterShadow } from '$/lib/theme'
  import ConfigureRegister from './ConfigureRegister.svelte'
  let show: boolean
  let name: string
  let first_name: string
  let middle_name: string
  let county: string
  let school: string
</script>

{#if show}
  <div class="fixed z-20  top-0 left-0 w-screen h-screen">
    <Delete bind:show />
  </div>
{/if}

<LayoutContext let:theme>
  <div
    class=" z-10 {text[theme]} {filterShadow[
      theme
    ]}   col-start-1 col-span-6 row-start-5 row-span-6 grid grid-cols-6 grid-rows-6 gap-x-md gap-y-sm mt-sm">
    <div class="col-start-2 row-start-1 text-center my-auto ">Actiuni cont</div>
    <div class="col-start-4 row-start-1 text-center my-auto ">Numele tau</div>
    <input
      class="col-span-2 col-start-5 bg-transparent row-start-1"
      bind:value={name}
      placeholder="Scrie-l aici" />
    <div class="col-start-4 row-start-2 text-center my-auto ">
      Primul prenume
    </div>
    <input
      class="col-span-2 col-start-5 bg-transparent row-start-2"
      bind:value={first_name}
      placeholder="Scrie-l aici" />
    <div class="col-start-4 row-start-3 text-center my-auto ">
      Al doilea prenume
    </div>
    <input
      class="col-span-2 col-start-5 bg-transparent row-start-3"
      bind:value={middle_name}
      placeholder="Scrie-l aici" />
    <div class="col-start-4 row-start-4 text-center my-auto ">
      Județul școlii tale
    </div>
    <input
      class="col-span-2 col-start-5 bg-transparent row-start-4"
      bind:value={county}
      placeholder="Scrie-l aici" />
    <div class="col-start-4 row-start-5 text-center my-auto ">Școala ta</div>
    <input
      class="col-span-2 col-start-5 bg-transparent row-start-5"
      bind:value={school}
      placeholder="Scrie-l aici" />
    <div class="col-start-1 col-span-3 row-start-4 text-center  my-auto ">
      Zona periculoasă
    </div>
    <button
      class="col-start-1 col-span-3 row-start-5 w-full h-full text-center text-sm my-auto {border
        .color[theme]} {border.size[
        theme
      ]} rounded hover:bg-red hover:border-red  "
      on:click={() => {
        show = true
      }}>
      Șterge-ți contul
    </button>
    <button
      class="col-start-1 col-span-3 w-full h-full row-start-3 text-center  my-auto {border
        .color[theme]} {border.size[theme]} rounded   ">
      Deconectează-te de la contul curent
    </button>
    <div class="col-span-3 col-start-1 row-start-2">
      <Become />
    </div>
    <div
      class=" col-start-4  h-full w-configure-login row-start-6  row-span-1 ">
      <ConfigureRegister />
    </div>
  </div></LayoutContext>
