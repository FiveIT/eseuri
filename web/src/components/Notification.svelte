<script context="module" lang="ts">
  import type { Theme } from '$/types'
  import Error from 'svelte-material-icons/AlertCircle.svelte'
  import ErrorBlue from 'svelte-material-icons/AlertCircleOutline.svelte'
  import Check from 'svelte-material-icons/CheckCircle.svelte'
  import CheckBlue from 'svelte-material-icons/CheckCircleOutline.svelte'
  import Information from 'svelte-material-icons/Information.svelte'
  import InformationBlue from 'svelte-material-icons/InformationOutline.svelte'
  import { slide } from 'svelte/transition'
  import { TRANSITION_EASING as easing } from '$/globals'

  interface Assets {
    /* The icon's Svelte component */
    icon: any
    color: string
  }

  type Status = 'good' | 'error' | 'info'

  const assets: Record<Status, Record<Theme, Assets>> = {
    good: {
      default: {
        icon: Check,
        color: 'dark-green',
      },
      white: {
        icon: CheckBlue,
        color: 'light-green',
      },
    },
    error: {
      default: {
        icon: Error,
        color: 'red',
      },
      white: {
        icon: ErrorBlue,
        color: 'red',
      },
    },
    info: {
      default: {
        icon: Information,
        color: 'grey',
      },
      white: {
        icon: InformationBlue,
        color: 'grey',
      },
    },
  }
</script>

<script lang="ts">
  import { text, border, filterShadow, background } from '$/theme'
  import { getLayout } from './Layout.svelte'
  import { px } from '$/util'
  import { tick } from 'svelte'

  const { theme: themeStore } = getLayout()

  export let type: Status
  export let message = 'Eroare'
  export let explanation = ''

  let detailsHeight: number
  let parent: HTMLDivElement

  let show = false

  async function handleMouseOver() {
    show = true

    await tick()

    parent.style.marginTop = `-${detailsHeight}px`
  }

  function handleMouseOut() {
    show = false

    parent.style.marginTop = ''
  }

  $: theme = $themeStore
  $: currentAssets = assets[type][theme]
</script>

<div
  class="w-notification_width bg-white min-h-notification_height z-10 rounded fixed top-4/5 left-3/4 transition-all duration-50 ease-out {text[
    theme
  ]} {border.color[theme]} {border.size[theme]} {filterShadow[
    theme
  ]} {background[theme]} text-sm font-sans antialiased leading-none"
  on:mouseenter={handleMouseOver}
  on:mouseleave={handleMouseOut}
  bind:this={parent}>
  <div class="flex align-middle items-center flex-col">
    <div class="flex w-full flex-row my-sm px-sm">
      <svelte:component
        this={currentAssets.icon}
        color="var(--{currentAssets.color})"
        size={px(2.5)} />
      <p class="mx-sm my-auto">
        {message}
      </p>
    </div>
    {#if show}
      <p
        class="mx-sm mb-sm origin-bottom"
        bind:offsetHeight={detailsHeight}
        transition:slide|local={{ easing, duration: 50 }}>
        {explanation}
      </p>
    {/if}
  </div>
</div>
