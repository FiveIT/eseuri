<script context="module" lang="ts">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import {
    TRANSITION_DURATION as duration,
    TRANSITION_EASING as easing,
  } from '$/globals'
  import type { BlobPropsInput, Theme } from '$/types'
  import { onDestroy, onMount, setContext } from 'svelte'
  import type { Readable, Writable } from 'svelte/store'
  import { writable } from 'svelte/store'
  import type { FlyParams } from 'svelte/transition'
  import { fly } from 'svelte/transition'

  export const contextKey = {}

  interface Context {
    alive: Writable<boolean>
    theme: Readable<Theme>
  }

  export type { Context }
</script>

<script lang="ts">
  const defaultTransition: FlyParams = {
    y: -1000,
    duration,
    easing,
  }

  export let transition: FlyParams = {}
  $: finalTransition = {
    ...defaultTransition,
    ...transition,
  }

  export let orangeBlobProps: BlobPropsInput = {}
  export let redBlobProps: BlobPropsInput = {}
  export let blueBlobProps: BlobPropsInput = {}

  export let blurBackground = false

  export let theme: Theme = 'default'

  export let afterMount = () => {}
  export let beforeDestroy = () => {}

  export let center = false

  const alive = writable(true)
  const themeStore = writable<Theme>(theme)
  // eslint-disable-next-line no-unused-vars
  $: $themeStore = theme

  setContext<Context>(contextKey, {
    alive,
    theme: themeStore,
  })

  let mounted = false
  onMount(() => {
    $alive = true
    // eslint-disable-next-line no-unused-vars
    $orange = orangeBlobProps
    // eslint-disable-next-line no-unused-vars
    $red = redBlobProps
    // eslint-disable-next-line no-unused-vars
    $blue = blueBlobProps

    setTimeout(() => {
      mounted = true
      afterMount()
    }, duration)
  })

  onDestroy(beforeDestroy)

  $: if (mounted) {
    $orange.x = orangeBlobProps.x ?? $orange.x
    $orange.y = orangeBlobProps.y ?? $orange.y

    $red.x = redBlobProps.x ?? $red.x
    $red.y = redBlobProps.y ?? $red.y

    $blue.x = blueBlobProps.x ?? $blue.x
    $blue.y = blueBlobProps.y ?? $blue.y
  }
</script>

{#if $alive}
  <div
    class="min-h-screen flex flex-col scrollbar-window-padding z-1"
    class:blur={blurBackground}
    class:white-bg={blurBackground}
    class:bg-opacity-50={blurBackground}
    transition:fly={finalTransition}>
    <div
      class="min-h-full mx-auto max-w-layout grid grid-cols-layout auto-rows-layout gap-x-md gap-y-sm py-xlg"
      class:my-auto={center}>
      <slot />
    </div>
  </div>
{/if}
