<script lang="ts">
  let name: string
  export let show: boolean
</script>

{#if show}
  <div
    class="fixed top-0 left-0 z-20 h-screen w-screen flex p-sm justify-center items-center">
    <div
      class="w-bookmark h-bookmark bg-white grid grid-rows-3 grid-cols-3 gap-x-md gap-y-sm  p-sm   rounded border-2 border-black">
      <div
        class="col-span-3 row-start-1 flex flex-col items-center align-middle">
        <div class="my-auto h-auto text-md">Creează un marcaj</div>
      </div>
      <div
        class="col-span-1 h-full row-start-2 flex flex-col items-center align-middle">
        <div class="my-auto h-auto text-sm">Nume</div>
      </div>
      <input
        placeholder="Scrie numele marcajului aici..."
        class="col-span-2 col-start-2 row-start-2 bg-white"
        bind:value={name} />
      <button
        class="col-start-2 h-full row-start-3  items-center align-middle"
        on:click={() => (show = !show)}>
        Salvează lucrarea
      </button>
    </div>
  </div>
{/if}
