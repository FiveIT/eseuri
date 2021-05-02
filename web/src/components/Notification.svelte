<script context="module" lang="ts">
  import type { Theme } from '$/lib/types'
  import Error from 'svelte-material-icons/AlertCircle.svelte'
  import ErrorBlue from 'svelte-material-icons/AlertCircleOutline.svelte'
  import Check from 'svelte-material-icons/CheckCircle.svelte'
  import CheckBlue from 'svelte-material-icons/CheckCircleOutline.svelte'
  import Information from 'svelte-material-icons/Information.svelte'
  import InformationBlue from 'svelte-material-icons/InformationOutline.svelte'
  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
  } from '$/lib/globals'
  import { slide, fade } from 'svelte/transition'

  interface Assets {
    /* The icon's Svelte component */
    icon: any
    color: string
  }

  type Status = 'success' | 'error' | 'info'

  export interface Payload {
    status: Status
    /**
     * The headline of the notification. It is a short summary
     * of the reason the notification appeared.
     */
    message: string
    /**
     * More details about the cause of the notification. It is
     * shown when the notification box is hovered over.
     */
    explanation?: string
  }

  const assets: Record<Status, Record<Theme, Assets>> = {
    success: {
      default: {
        icon: Check,
        color: 'green',
      },
      white: {
        icon: CheckBlue,
        color: 'green-light',
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
        color: 'gray',
      },
      white: {
        icon: InformationBlue,
        color: 'gray-light',
      },
    },
  }

  const iconShadow: Record<Theme, string> = {
    default: '',
    white: 'filter-shadow-soft',
  }

  const baseShadow: Record<Theme, string> = {
    default: 'filter-shadow-large',
    white: 'filter-shadow',
  }
</script>

<script lang="ts">
  import {
    text,
    border,
    filterShadow,
    background,
    innerShadow,
  } from '$/lib/theme'
  import { getLayout } from './Layout.svelte'
  import { px } from '$/lib/util'
  import { tick } from 'svelte'

  const { theme: themeStore } = getLayout()

  export let status: Status
  export let message: string
  export let explanation: string | undefined = undefined

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
  $: currentAssets = assets[status][theme]
</script>

<div
  class="w-notification min-h-notification z-10 rounded fixed top-4/5 left-3/4 transition-all duration-50 ease-out {text[
    theme
  ]} {border.color[theme]} {border.size[theme]} {baseShadow[
    theme
  ]}
  {background[theme]} {innerShadow[
    theme
  ]} text-sm font-sans antialiased leading-none flex flex-col"
  on:mouseenter={handleMouseOver}
  on:mouseleave={handleMouseOut}
  bind:this={parent}
  transition:fade={{ easing, duration }}>
  <div class="flex w-full h-notification flex-row items-center px-sm">
    <div class={iconShadow[theme]}>
      <svelte:component
        this={currentAssets.icon}
        color="var(--{currentAssets.color})"
        size={px(2.5)} />
    </div>
    <p class="mx-sm {filterShadow[theme]}">
      {message}
    </p>
  </div>
  {#if show && explanation}
    <p
      class="mx-sm mb-sm {filterShadow[theme]}"
      bind:offsetHeight={detailsHeight}
      transition:slide={{ easing, duration: 50 }}>
      {@html explanation}
    </p>
  {/if}
</div>
