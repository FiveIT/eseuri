<script lang="ts">
  import { createEventDispatcher } from 'svelte'

  export let response: boolean

  const dispatch = createEventDispatcher()
</script>

<button
  on:click={() => dispatch('response', response)}
  class="place-self-center h-2.33em w-4em rounded bg-{response
    ? 'white'
    : 'red'} border text-black font-sans text-sm antialiased h-full flex items-center justify-center text-center">
  <slot />
</button>
