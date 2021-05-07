<script lang="ts">
  import Delete from 'svelte-material-icons/CloseCircleOutline.svelte'

  export let name: string
  export let type: string
  export let subiect: string
  export let time: string
  export let todelete: boolean
  export let i: number
  export let position: number

  let clock = time.substring(0, 5)
  let date = time.substring(5, time.length)

  let show = false

  position = i
</script>

{#if !todelete}
  <div
    class="grid grid-rows-1 grid-cols-6 gap-x-md border-b-2 border-t-2 mb-sm h-row"
    on:mouseenter={() => (show = true)}
    on:mouseleave={() => (show = false)}>
    <div class="col-start-1 text-center my-auto">{type}</div>
    <div class="col-start-2 col-span-2 text-center my-auto">
      {name}
    </div>
    <div class="col-start-4 col-span-2 text-center my-auto">
      {subiect}
    </div>
    <div class="col-start-6 text-center my-auto">{clock}<br /> {date}</div>
    {#if show}
      <dt class=" fixed rounded   w-full text-center flex flex-row justify-start items-start">
        <button class=" mt-xs mr-sm " on:click={() => (todelete = true)}>
          <Delete size="1.8em" />
        </button>
      </dt>
    {/if}
  </div>
{/if}
