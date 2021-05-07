<script lang="ts">
  import { onMount } from 'svelte'
  import { LayoutContext } from '.'

  import { text, border, filterShadow, background } from '$/lib'

  let titleParent: HTMLElement
  let titleChild: HTMLElement
  let messageParent: HTMLElement
  let messageChild: HTMLElement
  let button1Parent: HTMLElement
  let button1Child: HTMLElement
  let button2Parent: HTMLElement
  let button2Child: HTMLElement

  export let show: boolean = true
  function fixFontSize(parent: HTMLElement, child: HTMLElement, compensation = 1) {
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
    fixFontSize(messageParent, messageChild, 3)
    fixFontSize(button1Parent, button1Child)
    fixFontSize(button2Parent, button2Child)
  })
</script>

<LayoutContext let:theme>
  {#if show}
    <div
      class="fixed flex justify-center items-center z-20 w-full h-full"
      class:blur={theme === 'default'}>
      <div
        class=" w-delete-box  h-association rounded z-20  grid grid-rows-5 grid-cols-4 gap-x-md gap-y-sm p-sm    {text[
          theme
        ]} {border.color[theme]} {border.size[theme]} {filterShadow[theme]} {background[theme]}">
        <div
          class="col-start-1 row-start-1 col-end-5   row-span-1 w-full h-full flex flex-col"
          bind:this={titleParent}>
          <span bind:this={titleChild} class="text-lg my-auto "
            >Ești sigur că vrei să-ți ștergi contul?</span>
        </div>
        <div class="col-span-4 row-start-2 row-end-5 " bind:this={messageParent}>
          <span class="text-sm" bind:this={messageChild}>
            Prin ștergerea contului îți pierzi toate marcajele și asocierile cu elevii/profesorii
            tăi. De altfel, îți pierzi și statutul de profesor pe platformă, dacă e cazul, iar în
            situația în care îți creezi un cont nou va trebui să redepui o cerere pentru a fi
            profesor. Lucrările tale nu vor fi șterse: acestea vor rămâne permanent pe platformă.
            Dacă totuși dorești să fie șterse <a href="mailto:info@example.com" class="underline"
              >contactează-ne pe email.</a>
          </span>
        </div>
        <button
          class="col-start-2 row-start-5  border-white border-2 rounded shadow flex flex-col justify-center items-center"
          class:bg-white={theme === 'white'}
          class:text-black={theme === 'white'}
          bind:this={button1Parent}
          on:click={() => {
            show = false
          }}>
          <span class="text-lg self-center w-min h-min " bind:this={button1Child}
            >Anulez ștergerea</span>
        </button>
        <button
          class="col-start-3 row-start-5   border-white border-2 rounded shadow  flex flex-col justify-center items-center"
          bind:this={button2Parent}>
          <span class="text-sm self-center w-full h-min " bind:this={button2Child}
            >Înțeleg, îmi șterg contul</span>
        </button>
      </div>
    </div>
  {/if}
</LayoutContext>
