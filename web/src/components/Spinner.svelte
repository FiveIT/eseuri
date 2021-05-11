<script context="module" lang="ts">
  import type { Theme, ThemeEntry } from '$/lib'
  import {
    placeholderText,
    TRANSITION_DURATION as duration,
    TRANSITION_EASING as easing,
  } from '$/lib'

  interface LongDurationOptions {
    after?: number
    message?: string
  }

  const longDurationDefaults: LongDurationOptions = {
    after: 5000,
    message: 'Încă puțin...',
  }

  const spinnerColor: Record<'main' | 'accent', ThemeEntry> = {
    accent: {
      default: 'gray-light',
      white: 'gray-light',
    },
    main: {
      default: 'gray',
      white: 'white',
    },
  }
</script>

<script lang="ts">
  import { onDestroy } from 'svelte'
  import { slide } from 'svelte/transition'
  import { getLayout } from '.'

  import Loading from 'svelte-material-icons/Loading.svelte'

  export let theme: Theme | undefined = undefined
  export let message: string | undefined = undefined
  export let longDuration: LongDurationOptions | null = longDurationDefaults
  export let size = '4em'

  if (longDuration) {
    longDuration = {
      ...longDurationDefaults,
      ...longDuration,
    }
  }

  let showLongDurationNotice = false
  const showLongDurationNoticeHandle =
    longDuration && setTimeout(() => (showLongDurationNotice = true), longDuration.after)

  const layout = getLayout()
  let themeStore: typeof layout.theme | undefined

  if (layout) {
    themeStore = layout.theme
  }

  $: t = theme || (themeStore && $themeStore) || 'default'

  onDestroy(() => {
    if (showLongDurationNoticeHandle) {
      clearTimeout(showLongDurationNoticeHandle)
    }
  })
</script>

<div class="flex flex-col space-md items-center justify-center">
  {#if message}
    <p class="text-md font-sans antialiased {placeholderText[t]}">
      {message}
    </p>
  {/if}
  <div class="relative w-{size} h-{size}">
    <div class="animate-spin-a absolute">
      <Loading color="var(--{spinnerColor.accent[t]})" size="100%" />
    </div>
    <div class="animate-spin-b absolute">
      <Loading color="var(--{spinnerColor.main[t]})" size="100%" />
    </div>
  </div>
  {#if longDuration && showLongDurationNotice}
    <p class="font-sans text-sm mt-md {placeholderText[t]}" transition:slide={{ duration, easing }}>
      {longDuration.message}
    </p>
  {/if}
</div>
