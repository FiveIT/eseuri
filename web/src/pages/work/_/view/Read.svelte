<script lang="ts" context="module">
  import { setContext, getContext } from 'svelte'
  import { writable } from 'svelte/store'
  import type { Writable, Readable } from 'svelte/store'

  import type { Work } from '..'

  const keys: Record<'prev' | 'next', Record<string, boolean>> = {
    prev: {
      ArrowLeft: true,
      KeyH: true,
      KeyK: true,
    },
    next: {
      ArrowRight: true,
      KeyL: true,
      KeyJ: true,
    },
  }

  const contextKey = {}

  const createWorkStore = (): Writable<Work | null> => writable(null)

  interface Context {
    work: Readable<Work | null>
    currentlyBookmarking: Writable<boolean>
  }

  export function getReader(): Context {
    return getContext(contextKey)
  }

  function setReader(ctx: Context) {
    setContext(contextKey, ctx)
  }
</script>

<script lang="ts">
  import { Next, Back, Bookmark } from '..'
  import Base from './Base.svelte'
  import { TRANSITION_EASING as easing, TRANSITION_DURATION as duration } from '$/lib'
  import { fly } from 'svelte/transition'

  export let work: Work

  let disablePrevious = true
  let disableNavigation = false

  const workStore = createWorkStore()
  const currentlyBookmarking = writable(false)
  setReader({ work: workStore, currentlyBookmarking })

  $: {
    disableNavigation = true

    work.data
      .then(w => (($workStore = work), w))
      .finally(() => {
        disableNavigation = false
      })
  }

  const update = () => {
    work = work
  }

  let direction = 1

  const next = () => {
    if (disableNavigation || $currentlyBookmarking) {
      return
    }

    work.next()
    disablePrevious = false
    update()
  }

  const prev = async () => {
    if (disableNavigation || disablePrevious || $currentlyBookmarking) {
      return
    }

    direction = -1
    disablePrevious = !(await work.prev())
    update()
    direction = 1
  }

  function onKey({ code }: KeyboardEvent) {
    if (keys.prev[code]) {
      prev()
    } else if (keys.next[code]) {
      next()
    }
  }
</script>

<Base {work} transitionFn={fly} transitionProps={{ x: direction * -200, duration, easing }}>
  <Bookmark slot="heading" />
  <Back disabled={disablePrevious} on:click={prev} />
  <Next on:click={next} />
  <Bookmark slot="footer" />
</Base>

<svelte:window on:keydown={onKey} />
