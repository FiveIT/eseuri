<script lang="ts">
  import Submit from './Submit.svelte'
  import NavButton from '$/components'

  export let submitValue: string | undefined = undefined
  export let abortHref = '/'
  export let abortLabel = 'Înapoi'
</script>

<div class="row-end-7 col-start-3 col-span-2 grid auto-cols-layout grid-flow-col gap-x-md">
  <Submit value={submitValue}><slot /></Submit>
  <NavButton href={abortHref} on:navigate>{abortLabel}</NavButton>
</div>
