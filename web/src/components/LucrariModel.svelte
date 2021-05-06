<script lang="ts">
  export let teacher: string
  export let type: string
  export let subiect: string
  export let time: string
  let clock = time.substring(0, 5)
  let date = time.substring(5, time.length)
  let show = false
</script>

<div class="grid grid-cols-5 gap-x-md border-b-2 border-t-2  h-full">
  <div class="col-start-1 text-center my-auto">{type}</div>
  <div class="col-start-2 col-span-2 text-center my-auto">
    {subiect}
  </div>
  <div class="col-start-4 text-center my-auto">
    {clock}<br />
    {date}
  </div>
  <div
    class="col-start-5 text-center h-full flex justify-center align-middle"
    on:mouseenter={() => (show = true)}>
    <div class="h-min z-10 w-full my-auto">{teacher}</div>
    {#if show}
      <div
        class=" ml-teacherdisplacement h-teacherdescriptionheight z-20  fixed self-start "
        on:mouseleave={() => (show = false)}>
        <dl
          class="  rounded  w-teacherdescriptionwidth h-teacherdescriptionheight bg-blue border-3 border-white text-center grid grid-flow-row grid-rows-4 gap-y-xs px-sm py-xs font-sans antialiased  leading-none">
          <dt class="row-span-2 h-full flex flex-row">
            <h2 class="text-md mt-auto">
              {teacher}
            </h2>
          </dt>
          <dt class=" row-start-3 h-full flex flex-row">
            <span class="text-workInfo  my-auto">PoescuIon@yahoo.com</span>
          </dt>
          <dt class=" row-start-4 h-full flex flex-row">
            <span class="text-workInfo  my-auto"> Agricol 'Suceava' </span>
          </dt>
        </dl>
      </div>{/if}
  </div>
</div>
