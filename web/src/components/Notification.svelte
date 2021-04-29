<script context="module" lang="ts">
  import type { Theme } from '$/types'
  import Error from 'svelte-material-icons/AlertCircle.svelte'
  import ErrorBlue from 'svelte-material-icons/AlertCircleOutline.svelte'
  import Check from 'svelte-material-icons/CheckCircle.svelte'
  import CheckBlue from 'svelte-material-icons/CheckCircleOutline.svelte'
  import Information from 'svelte-material-icons/Information.svelte'
  import InformationBlue from 'svelte-material-icons/InformationOutline.svelte'
  import { TRANSITION_EASING as easing } from '$/globals'
  import { slide, fade } from 'svelte/transition'

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

  const { theme: themeStore } = getLayout()

  export let type: Status
  export let message: string = 'Eroare'
  export let explanation: string = ''

  let show: boolean = false
  let hide: boolean = false
  function handleMouseOver() {
    show = true
    hide = true
  }

  function handleMouseOut() {
    show = false
  }

  $: theme = $themeStore
  $: currentAssets = assets[type][theme]
</script>

{#if (!hide && !show) || show}
  {setTimeout(function () {
    if (type !== 'error') {
      hide = true
      show = false
    }
  }, 5000)}}
  <div
    class="w-notification_width bg-white min-h-notification_height z-10 rounded fixed top-3/4 left-3/4 transition duration-50 ease-out {text[
      theme
    ]} {border.color[theme]} {border.size[theme]} {filterShadow[
      theme
    ]} {background[theme]} text-sm font-sans antialiased leading-none"
    transition:fade={{ duration: 500 }}
    on:mouseenter={handleMouseOver}
    on:mouseleave={handleMouseOut}>
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
      {#if show && explanation !== ''}
        <p
          class="mx-sm mb-sm"
          transition:slide|local={{ easing, duration: 50 }}>
          {explanation}
        </p>
      {/if}
    </div>
  </div>
{/if}
