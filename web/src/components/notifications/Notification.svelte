<script context="module" lang="ts">
  import type { Theme, NotificationStatus as Status } from '$/lib'
  import Error from 'svelte-material-icons/AlertCircle.svelte'
  import ErrorBlue from 'svelte-material-icons/AlertCircleOutline.svelte'
  import Check from 'svelte-material-icons/CheckCircle.svelte'
  import CheckBlue from 'svelte-material-icons/CheckCircleOutline.svelte'
  import Information from 'svelte-material-icons/Information.svelte'
  import InformationBlue from 'svelte-material-icons/InformationOutline.svelte'
  import { TRANSITION_EASING as easing, TRANSITION_DURATION as duration } from '$/lib'
  import { slide, fade } from 'svelte/transition'

  interface Assets {
    /* The icon's Svelte component */
    icon: any
    color: string
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
  import { text, border, filterShadow, background, innerShadow } from '$/lib/theme'
  import { getTheme } from '$/pages/_layout.svelte'
  import { px } from '$/lib/util'
  import { tick } from 'svelte'

  const themeStore = getTheme()

  // properties are the same as in $/lib/types.Notification
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
  class="w-notification min-h-notification z-10 rounded fixed top-4/5 left-3/4 transition-all duration-50 ease-out focus-visible:outline-solid-black {text[
    theme
  ]} {border.color[theme]} {border.all[theme]} {baseShadow[theme]}
  {background[
    theme
  ]} {innerShadow[theme]} text-sm font-sans antialiased leading-none flex flex-col"
  on:focus={handleMouseOver}
  on:blur={handleMouseOut}
  on:touchstart={handleMouseOver}
  on:touchend={handleMouseOut}
  on:mouseenter={handleMouseOver}
  on:mouseleave={handleMouseOut}
  tabindex={1}
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
      in:slide={{ easing, duration: 50 }}>
      {@html explanation}
    </p>
  {/if}
</div>
