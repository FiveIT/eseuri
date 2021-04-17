<script lang="ts">
  export let formenctype = 'application/x-www-form-urlencoded'
  export let value: string
</script>

<input
  type="submit"
  {formenctype}
  {value}
  class="col-span-1 h-full rounded text-white text-sm bg-blue cursor-pointer" />
