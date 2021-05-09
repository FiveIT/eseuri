<script>
  import { getForm } from '../Form.svelte'

  const { rows, cols, hasTitle } = getForm()

  $: rowStart = rows + 2 * +$hasTitle
</script>

<div class="row-start-{rowStart} col-span-{3 * cols} flex justify-center h-full">
  <div class="grid grid-flow-col auto-cols-layout h-full gap-x-md">
    <slot />
  </div>
</div>
