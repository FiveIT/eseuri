<script lang="ts" context="module">
  import { notify } from '$/components'
  import { internalErrorNotification } from '$/lib'

  import { setContext, getContext } from 'svelte'
  import { writable } from 'svelte/store'
  import type { Writable, Readable } from 'svelte/store'
  import Modal, { openModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

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

  export async function bookmark(work: Work, currentlyBookmarking: Writable<boolean>) {
    currentlyBookmarking.set(true)
    await openModal(work)
    currentlyBookmarking.set(false)
  }

  export async function removeBookmark(work: Work) {
    try {
      await work.removeBookmark()

      notify({
        status: 'success',
        message: 'Lucrarea nu mai este salvată!',
      })
    } catch {
      notify({
        ...internalErrorNotification,
        message: `Eroare la anularea salvării lucrării: ${internalErrorNotification.message.toLocaleLowerCase(
          'ro-RO'
        )}`,
      })
    }
  }

</script>

<script lang="ts">
  import { Next, Back, Bookmark } from '..'
  import Base from './Base.svelte'
  import Create from '../bookmark/Modal.svelte'
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

  const { bookmarked } = work

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

  function onKey(ev: KeyboardEvent) {
    if ($currentlyBookmarking || ev.altKey) {
      return
    }

    const { code } = ev
    let handler: (() => void) | undefined

    if (keys.prev[code]) {
      handler = prev
    } else if (keys.next[code]) {
      handler = next
    } else if (code === 'KeyB') {
      if ($bookmarked) {
        handler = () => removeBookmark(work)
      } else {
        handler = () => bookmark(work, currentlyBookmarking)
      }
    }

    if (handler) {
      ev.preventDefault()
      handler()
    }
  }

</script>

<Base {work} transitionFn={fly} transitionProps={{ x: direction * -200, duration, easing }}>
  <Bookmark slot="heading" />
  <Back disabled={disablePrevious} on:click={prev} />
  <Next on:click={next} />
  <Bookmark slot="footer" />
</Base>

<Modal let:payload>
  {#if payload}
    <Create work={payload} />
  {/if}
</Modal>

<svelte:window on:keyup={onKey} />
