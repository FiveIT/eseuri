<script>
  import { getForm } from '../Form.svelte'

  const { rows, cols } = getForm()
</script>

<div class="row-start-{rows + 2} col-span-{3 * cols} flex justify-center">
  <div class="grid grid-flow-col auto-cols-layout h-full gap-x-md">
    <slot /> 
  </div>
</div>
