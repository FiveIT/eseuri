<script lang="ts">
  import AssociateButton from '$/components/AssociateButton.svelte'
  import AssociateCard from '$/components/AssociateCard.svelte'

  import { asociates } from '$/content'

  let todelete: boolean
  $: if (todelete == true) {
    todelete = false
    asociates.splice(position)
    console.log(position)
  }
  let position: number
</script>

<div
  class="row-start-5 col-span-6 col-start-1 grid grid-cols-essays auto-rows-essays gap-x-md gap-y-sm ">
  <AssociateButton />
  {#each asociates as associate, i}
    <AssociateCard work={associate} {todelete} {i} bind:position />
  {/each}
</div>
