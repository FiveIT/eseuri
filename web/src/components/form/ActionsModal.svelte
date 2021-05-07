<script lang="ts">
  import ActionsBase from './internal/ActionsBase.svelte'
  import { LayoutContext } from '..'
  import { text } from '$/lib/theme'

  export let submitValue: string | undefined = undefined
  export let closeFn: (() => void) | undefined = undefined
  export let closeLabel = 'Anulează'

  function onKeyup({ code }: KeyboardEvent) {
    if (code !== 'Escape') {
      return
    }

    closeFn?.()
  }

  console.log({ closeFn })
</script>

<LayoutContext let:theme>
  <ActionsBase {submitValue}>
    <slot />
    <button
      slot="abort"
      on:click={closeFn}
      class="flex-1 {text[theme]} text-sm font-sans antialiased">{closeLabel}</button>
  </ActionsBase>
</LayoutContext>

<svelte:window on:keyup={onKeyup} />
