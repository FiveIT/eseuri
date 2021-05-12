<script lang="ts">
  import ActionsBase from './internal/ActionsBase.svelte'
  import { LayoutContext } from '..'
  import { text } from '$/lib/theme'
  import { closeModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  export let submitValue: string | undefined = undefined
  export let closeFn: () => void = closeModal
  export let closeLabel = 'Anulează'

  function onKeyup(e: KeyboardEvent) {
    if (e.code !== 'Escape' || e.altKey) {
      return
    }

    closeFn?.()
  }

</script>

<LayoutContext let:theme>
  <ActionsBase {submitValue}>
    <slot />
    <button
      slot="abort"
      type="button"
      on:click={closeFn}
      class="flex-1 {text[theme]} text-sm font-sans antialiased leading-none">{closeLabel}</button>
  </ActionsBase>
</LayoutContext>

<svelte:window on:keyup={onKeyup} />
