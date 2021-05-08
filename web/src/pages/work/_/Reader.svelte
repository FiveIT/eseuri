<script lang="ts" context="module">
  import { setContext, getContext } from 'svelte'
  import { writable } from 'svelte/store'
  import type { Writable, Readable } from 'svelte/store'

  import type { Work, WorkData } from '.'

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

  const getParagraphs = (text: string) =>
    text
      .trim()
      .split(/(?:\r?\n)+/)
      .map(p => p.trim())
</script>

<script lang="ts">
  import { Next, Back, Bookmark } from '.'
  import { notify, Spinner } from '$/components'
  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
    internalErrorNotification,
    workTypeTranslation,
    title,
  } from '$/lib'
  import { fade, fly } from 'svelte/transition'
  import { isAuthenticated } from '@tmaxmax/svelte-auth0'

  export let work: Work

  let disablePrevious = true
  let disableNavigation = false
  let data: Promise<WorkData>

  const workStore = createWorkStore()
  const currentlyBookmarking = writable(false)
  setReader({ work: workStore, currentlyBookmarking })

  $: {
    disableNavigation = true

    data = work.data
      .then(w => (($workStore = work), w))
      .catch(() => {
        notify(internalErrorNotification)

        return { id: '', content: '', workID: 0 }
      })
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

<article class="col-start-2 col-end-6 row-start-3 flex flex-col justify-between relative">
  <header class="space-y-sm">
    <h1 class="text-title font-serif antialiased">
      {work.title}
    </h1>
    <div class="flex justify-between align-middle">
      <div class="w-min text-sm font-sans antialiased">
        {title(workTypeTranslation.ro[work.type].inarticulate.singular)}
      </div>
      <div class="w-min">
        {#if $isAuthenticated}
          <Bookmark />
        {/if}
      </div>
    </div>
  </header>
  {#await data}
    <div class="col-span-6 flex justify-center items-center my-lg">
      <Spinner />
    </div>
  {:then { content }}
    <main
      class="mt-lg space-y-sm"
      in:fade={{ duration, easing, delay: duration }}
      out:fly={{ x: direction * -200, duration, easing }}>
      {#each getParagraphs(content) as paragraph}
        <p class="text-prose font-serif antialiased">
          {paragraph}
        </p>
      {/each}
    </main>
  {/await}
</article>
<Back disabled={disablePrevious} on:click={prev} />
<Next on:click={next} />
{#if $isAuthenticated}
  <div class="col-start-2">
    <Bookmark />
  </div>
{/if}

<svelte:window on:keydown={onKey} />
