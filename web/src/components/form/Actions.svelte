<script lang="ts">
  import Submit from './Submit.svelte'
  import NavButton from '../NavButton.svelte'

  export let formenctype = 'application/x-www-form-urlencoded'
  export let submitValue: string
  export let abortHref = '/'
  export let abortLabel = 'Înapoi'
</script>

<div class="row-end-7 col-start-3 col-span-2 grid auto-cols-layout grid-flow-col gap-x-md">
  <Submit value={submitValue} {formenctype} />
  <NavButton href={abortHref} on:navigate>{abortLabel}</NavButton>
</div>
