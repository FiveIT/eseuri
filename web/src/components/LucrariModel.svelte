<script lang="ts">
  export let teacher: string
  export let type: string
  export let subiect: string
  export let time: string
  let clock = time.substring(0, 5)
  let date = time.substring(5, time.length)
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
  <div class="col-start-5 text-center my-auto">{teacher}</div>
</div>
