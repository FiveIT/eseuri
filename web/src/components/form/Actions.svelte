<script lang="ts">
  import ActionsBase from './internal/ActionsBase.svelte'
  import { NavButton } from '$/components'

  export let submitValue: string | undefined = undefined
  export let abortHref = '/'
  export let abortLabel = 'Înapoi'
</script>

<ActionsBase {submitValue}>
  <slot />
  <NavButton slot="abort" href={abortHref} on:navigate>{abortLabel}</NavButton>
</ActionsBase>
