<script>
  import AssociateButton from './AssociateButton.svelte'
  import AssociateCard from './AssociateCard.svelte'

  import { asociates } from '$/content'
</script>

<div
  class="row-start-5 col-span-6 col-start-1 grid grid-cols-essays auto-rows-essays gap-x-md gap-y-sm ">
  <AssociateButton />
  {#each asociates as associate}
    <AssociateCard work={associate} />
  {/each}
</div>
