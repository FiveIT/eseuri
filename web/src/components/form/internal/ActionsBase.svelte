<script lang="ts">
  import Submit from '../Submit.svelte'
  import ActionsLayout from './ActionsLayout.svelte'
  import { getForm } from '../Form.svelte'

  const { disabled } = getForm()

  export let submitValue: string | undefined = undefined
</script>

<ActionsLayout>
  {#if !$disabled}
    <Submit value={submitValue}><slot /></Submit>
  {/if}
  <slot name="abort" />
</ActionsLayout>
