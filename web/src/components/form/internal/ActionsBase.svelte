<script lang="ts">
  import Submit from '../Submit.svelte'
  import { getForm } from '../Form.svelte'

  const { rows, cols, disabled } = getForm()

  export let submitValue: string | undefined = undefined
</script>

<div class="row-start-{rows + 2} col-span-{3 * cols} flex justify-center">
  <div class="grid grid-flow-col auto-cols-layout h-full gap-x-md">
    {#if !$disabled}
      <Submit value={submitValue}><slot /></Submit>
    {/if}
    <slot name="abort" />
  </div>
</div>
