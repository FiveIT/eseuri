<script lang="ts">
  import Error from 'svelte-material-icons/AlertCircle.svelte'
  import ErrorBlue from 'svelte-material-icons/AlertCircleOutline.svelte'
  import Check from 'svelte-material-icons/CheckCircle.svelte'
  import CheckBlue from 'svelte-material-icons/CheckCircleOutline.svelte'
  import Information from 'svelte-material-icons/Information.svelte'
  import InformationBlue from 'svelte-material-icons/InformationOutline.svelte'
  import LayoutContext from './LayoutContext.svelte'
  import { text, border, filterShadow, background } from '$/theme'
  import { px } from '$/util'
  import { slide } from 'svelte/transition'
  export let type: string
  export let message: string = 'Eroare'
  export let explanation: string = ''
  let show: boolean = false
  function handleMouseOver() {
    console.log('lala')
    show = true
  }
  function handleMouseOut() {
    show = false
  }
</script>

<LayoutContext let:theme>
  <div
    class="w-notification_width bg-white  min-h-notification_height z-10 rounded border-2 fixed top-3/4 left-3/4 notification {text[
      theme
    ]} {border.color[theme]} {border.size[theme]} {filterShadow[
      theme
    ]} {background[theme]}"
    on:mouseenter={handleMouseOver}
    on:mouseleave={handleMouseOut}>
    {#if type === 'error'}
      <div class="w-full  flex align-middle items-center flex-col ">
        <div class="w-full h-full flex flex-row my-sm px-sm">
          {#if background[theme] == 'bg-white'}
            <Error color="var(--red)" size={px(2.5)} />
          {:else}
            <ErrorBlue color="var(--red)" size={px(2.5)} />
          {/if}
          <p class="mx-sm my-auto">{message}</p>
        </div>
        {#if show}
          <p class="mx-sm my-auto p-sm" transition:slide|local>
            {explanation}
          </p>
        {/if}
      </div>
    {:else if type === 'good'}
      <div class="w-full  flex align-middle items-center flex-col">
        <div class="w-full flex flex-row my-sm px-sm">
          {#if background[theme] == 'bg-white'}
            <Check color="var(--dark-green)" size={px(2.5)} />
          {:else}
            <CheckBlue color="var(--light-green)" size={px(2.5)} />
          {/if}
          <p class="mx-sm my-auto ">
            {message}
          </p>
        </div>
        {#if show}
          <p class="mx-sm my-auto">
            {explanation}
          </p>
        {/if}
      </div>
    {:else}
      <div class="w-full  flex align-middle items-center flex-col">
        <div class="w-full flex flex-row my-sm px-sm">
          {#if background[theme] == 'bg-white'}
            <Information color="var(--gray)" size={px(2.5)} />
          {:else}
            <InformationBlue color="var(--light-gray)" size={px(2.5)} />
          {/if}
          <p class="mx-sm my-auto">{message}</p>
        </div>
        {#if show}
          <p class="mx-sm my-auto">
            {explanation}
          </p>
        {/if}
      </div>
    {/if}
  </div>
</LayoutContext>

<style>
  .notification {
    transition: all 1s ease-in-out;
  }
</style>
