<script lang="ts">
  import { onMount } from 'svelte'
  import LayoutContext from './LayoutContext.svelte'

  import { text, border, filterShadow, background } from '$/theme'

  let titleParent: HTMLElement
  let titleChild: HTMLElement
  let nameParent: HTMLElement
  let nameChild: HTMLElement
  let emailParent: HTMLElement
  let emailChild: HTMLElement
  let button1Parent: HTMLElement
  let button1Child: HTMLElement
  let button2Parent: HTMLElement
  let button2Child: HTMLElement
  let show: boolean = true
  function fixFontSize(
    parent: HTMLElement,
    child: HTMLElement,
    compensation = 1
  ) {
    const { height: parentHeight } = parent.getBoundingClientRect()
    const { height: nameHeight } = child.getBoundingClientRect()

    if (nameHeight > parentHeight) {
      const p = parentHeight / nameHeight
      const fontSize = parseInt(window.getComputedStyle(child).fontSize)
      child.style.fontSize = `${p * compensation * fontSize}px`
    }
  }

  onMount(() => {
    fixFontSize(titleParent, titleChild, 1.5)
    fixFontSize(nameParent, nameChild)
    fixFontSize(emailParent, emailChild)
    fixFontSize(button1Parent, button1Child)
    fixFontSize(button2Parent, button2Child)
  })
  let name: string
  let email: string
</script>

<LayoutContext let:theme>
  {#if show}
    <div
      class="w-screen h-screen  fixed top-0 left-0 flex justify-center items-center z-1"
      class:blur={theme === 'default'}>
      <div
        class=" w-associationboxwidth h-associationboxheight rounded z-20  grid grid-rows-5 grid-cols-3 gap-x-md gap-y-sm p-sm    {text[
          theme
        ]} {border.color[theme]} {border.size[theme]} {filterShadow[
          theme
        ]} {background[theme]}">
        <div
          class="col-start-1 row-start-1 col-end-3   row-span-1 w-full h-full flex flex-col"
          bind:this={titleParent}>
          <span bind:this={titleChild} class="text-lg my-auto "
            >Inițiază o asociere</span>
        </div>
        <div
          class="col-start-1 col-span-1 row-span-1 row-start-2    flex flex-col h-full justify-center"
          bind:this={nameParent}>
          <span bind:this={nameChild} class="text-lg  self-center text-center  "
            >Numele profesorului</span>
        </div>
        <input
          bind:value={name}
          class=" col-span-2 col-start-2 row-start-2 bg-blue placeholder-gray-light text-gray-light"
          placeholder="Scrie-l aici..." />
        <div
          class="col-start-1 row-start-3 row-span-1     flex flex-col justify-center"
          bind:this={emailParent}>
          <span
            bind:this={emailChild}
            class="text-lg  self-center  text-center  ">Email-ul său</span>
        </div>
        <input
          type="text"
          class=" col-span-2 col-start-2 row-start-3 bg-blue placeholder-gray-light text-gray-light"
          placeholder="Scrie-l aici..."
          bind:value={email} />
        <div
          class="col-start-1 row-start-5    border-white border-2 rounded shadow flex flex-col justify-center items-center"
          bind:this={button1Parent}>
          <span
            class="text-lg self-center w-min h-min "
            bind:this={button1Child}>Trimite cererea</span>
        </div>
        <button
          class="col-start-2 row-start-5   border-white border-2 rounded shadow  flex flex-col justify-center items-center"
          bind:this={button2Parent}
          on:click={() => {
            show = false
          }}>
          <span class="text-lg self-center w-min h-min" bind:this={button2Child}
            >Anuleaza cererea</span>
        </button>
      </div>
    </div>
  {/if}
</LayoutContext>
