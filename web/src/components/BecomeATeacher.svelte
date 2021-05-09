<script lang="ts">
  import { LayoutContext } from '.'
  import { text, border, background } from '$/lib'

  let isregistered: boolean | any
  let isrecorded: boolean | any
  let isaccepted: boolean | any
  let time: string
  function handleClick() {
    if (isregistered == null) {
      isregistered = true
    } else {
      if (isrecorded == null) {
        time = new Date().toLocaleString()
        isrecorded = true
      } else {
        if (isaccepted == null) {
          isaccepted = true
        } else {
          if (isaccepted == false) {
            isregistered = null
            isrecorded = null
            isaccepted = null
          }
        }
      }
    }
  }
  ///time = new Date().toLocaleString()
</script>

<LayoutContext let:theme>
  <button
    class="border-orange border-green-light border-white border-red bg-blue bg-red bg-green-light {text[
      theme
    ]} {border.all[theme]}  {background[theme]} rounded w-full h-full"
    class:border-white={isregistered}
    class:border-orange={isrecorded}
    class:border-green-light={isaccepted}
    class:border-red={!isaccepted && isrecorded}
    class:bg-green-light={isaccepted}
    class:bg-blue={(isregistered || isrecorded) && isaccepted == null}
    class:bg-red={!isaccepted && isaccepted != null && time != null}
    on:click={handleClick}>
    {#if !isregistered}
      Înregisrează-te pentru a deveni profeso
    {:else if !isrecorded}
      Devino profesor
    {:else if isrecorded && isaccepted == null}
      Cererea ta de a deveni profesor din {time} este în revizuire
    {:else if isaccepted}
      Ești profesor
    {:else}
      Cererea ta de a deveni profesor din {time} a fost refuzată. Click pentru a retrimite.
    {/if}
  </button>
</LayoutContext>
