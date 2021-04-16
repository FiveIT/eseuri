<script context="module" lang="ts">
  export const alive = writable(true)
</script>

<script lang="ts">
  import { onMount } from 'svelte'
  import { writable } from 'svelte/store'
  import { fly } from 'svelte/transition'
  import type { FlyParams } from 'svelte/transition'

  import { defaultBlobProps } from '$/components/blob/internal/store'

  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'

  export let transition: FlyParams = {
    y: -1000,
    duration: 300,
  }

  export let orangeBlobProps = defaultBlobProps()
  export let redBlobProps = defaultBlobProps()
  export let blueBlobProps = defaultBlobProps()

  let mounted = false
  onMount(() => {
    $alive = true
    // eslint-disable-next-line no-unused-vars
    $orange = orangeBlobProps
    // eslint-disable-next-line no-unused-vars
    $red = redBlobProps
    // eslint-disable-next-line no-unused-vars
    $blue = blueBlobProps

    mounted = true
  })

  $: if (mounted) {
    void 0
  }
</script>

{#if $alive}
  <div
    class="min-h-full mx-auto max-w-layout grid grid-cols-layout auto-rows-layout gap-x-md gap-y-sm"
    transition:fly={transition}>
    <slot />
  </div>
{/if}
