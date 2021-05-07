<script lang="ts">
  // import { onMount } from 'svelte'

  import { LayoutContext } from '.'
  import Delete from 'svelte-material-icons/CloseCircleOutline.svelte'
  import { text, filterShadow, border } from '$/lib'
  import type { Associate } from '$/lib'

  let titleParent: HTMLElement
  let titleChild: HTMLElement
  let creatorParent: HTMLElement
  let creatorChild: HTMLElement
  let messageParent: HTMLElement
  let messageChild: HTMLElement
  let schoolParent: HTMLElement
  let schoolChild: HTMLElement

  // function fixFontSize(
  //   parent: HTMLElement,
  //   child: HTMLElement,
  //   compensation = 1
  // ) {
  //   const { height: parentHeight } = parent.getBoundingClientRect()
  //   const { height: childHeight } = child.getBoundingClientRect()
  //   console.log(parent.getBoundingClientRect())
  //   console.log(child.getBoundingClientRect())

  //   if (childHeight > parentHeight) {
  //     const p = parentHeight / childHeight
  //     const fontSize = parseInt(window.getComputedStyle(child).fontSize)
  //     child.style.fontSize = `${p * compensation * fontSize}px`
  //   }
  // }
  let show = false

  export let todelete: boolean
  export let i: number
  export let position: number
  position = i
  export let work: Associate
  // onMount(() => {
  //   console.log(titleParent)
  //   fixFontSize(titleParent, titleChild, 1.5)
  //   console.log(creatorParent)
  //   fixFontSize(creatorParent, creatorChild)
  //   console.log(schoolParent)
  //   fixFontSize(schoolParent, schoolChild)
  //   console.log(messageParent)
  //   fixFontSize(messageParent, messageChild)
  // })
</script>

{#if !todelete}
  <LayoutContext let:theme>
    {#if work.status == 'Incoming'}
      <div
        class="grid grid-rows-2 grid-cols-2 rounded border border-3px text-white h-full text-center mt-sm w-full ws {border
          .size[theme]} {filterShadow[theme]} ">
        <div class="col-span-2 text-center my-auto font-sans ">
          Asociere cu:<br />{work.name}
        </div>
        <button
          on:click={() => (todelete = true)}
          class="col-start-1 row-start-2 text-center border rounded bg-white text-black  mx-md my-sm">
          Da
        </button>
        <button
          on:click={() => (todelete = true)}
          class="col-start-2 row-start-2 text-center border rounded bg-red text-black mx-md my-sm">
          Nu
        </button>
      </div>
    {:else}
      <div
        class=" wr mt-sm w-full rounded {border.size[
          theme
        ]} h-full border-white  border-red border-orange  z-20  grid w-full grid-flow-row h-full opacity-80  grid-rows-4 gap-y-xs px-sm py-xs font-sans antialiased  leading-none {text[
          theme
        ]}  {filterShadow[theme]} 
     "
        class:border-red={work.status == 'Rejected'}
        class:border-orange={work.status == 'Pending'}
        class:wr={work.status == 'Pending' || work.status == 'Rejected'}
        on:mouseenter={() => (show = true)}
        on:mouseleave={() => (show = false)}
        class:opacity-80={show && (work.status == 'Pending' || work.status == 'Rejected')}>
        <dt class="row-span-2 row-start-1 h-full flex flex-col" bind:this={titleParent}>
          <h2 class="text-md mt-auto" bind:this={titleChild}>
            {work.name}
          </h2>
        </dt>
        <dt class=" row-start-3 h-full flex flex-col" bind:this={creatorParent}>
          <span class="text-workInfo  my-auto" bind:this={creatorChild}>{work.email}</span>
        </dt>
        <dt class=" row-start-4 h-full flex flex-col" bind:this={schoolParent}>
          <span class="text-workInfo  my-auto" bind:this={schoolChild}>
            {work.school}
          </span>
        </dt>
        {#if show && (work.status == 'Pending' || work.status == 'Rejected')}
          <dt class=" fixed rounded hover h-full w-full text-center flex" bind:this={messageParent}>
            <span
              class="self-center mx-auto my-auto text-white text-md text-opacity-10 "
              bind:this={messageChild}>
              {#if work.status == 'Pending'}
                Cerere în așteptare
              {:else if work.status == 'Rejected'}
                Cerere refuzată
              {/if}
            </span>
          </dt>
        {/if}
        {#if show && work.status == 'Accepted'}
          <dt
            class=" fixed rounded  h-full w-full text-center flex flex-row justify-end items-start"
            bind:this={messageParent}>
            <button class=" mt-xs mr-sm " on:click={() => (todelete = true)}>
              <Delete size="1.8em" />
            </button>
          </dt>
        {/if}
      </div>
    {/if}
  </LayoutContext>
{/if}

<style>
  .wr {
    background: rgba(0, 0, 0, 0.5);
  }
  .ws {
    background: rgba(0, 0, 0, 0.5);
  }
  .hover {
    background: rgba(0, 0, 0, 0.8);
  }
</style>
