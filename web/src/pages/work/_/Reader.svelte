<script lang="ts" context="module">
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
</script>

<script lang="ts">
  import { Next, Back, Bookmark, Spinner, notify, internalErrorNotification } from '.'
  import type { Work, WorkData } from '.'
  import { TRANSITION_EASING as easing, TRANSITION_DURATION as duration } from '$/lib/globals'
  import { fade, fly } from 'svelte/transition'

  export let work: Work

  let disablePrevious = true
  let disableNavigation = false
  let data: Promise<WorkData>

  $: {
    disableNavigation = true

    data = work.data
      .catch(() => (notify(internalErrorNotification), { id: '', content: '' } as WorkData))
      .finally(() => (disableNavigation = false))
  }

  const update = () => {
    work = work
  }

  let direction = 1

  const next = () => {
    if (disableNavigation) {
      return
    }

    work.next()
    disablePrevious = false
    update()
  }

  const prev = async () => {
    if (disableNavigation || disablePrevious) {
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

<div class="col-start-2 col-end-6 row-start-3 flex flex-col justify-between relative">
  <h2 class="text-title font-serif antialiased">
    {work.title}
  </h2>
  <div class="flex justify-between align-middle">
    <div class="w-min text-sm font-sans antialiased">Eseu</div>
    <div class="w-min"><Bookmark /></div>
  </div>
  {#await data}
    <div class="col-span-6 flex justify-center items-center my-lg">
      <Spinner />
    </div>
  {:then text}
    <p
      class="text-prose font-serif antialiased my-lg whitespace-pre-line"
      in:fade={{ duration, easing, delay: duration }}
      out:fly={{ x: direction * -200, duration, easing }}>
      {text.content.trim()}
    </p>
  {/await}
</div>
<Back disabled={disablePrevious} on:click={prev} />
<Next on:click={next} />
<div class="col-start-2">
  <Bookmark />
</div>

<svelte:window on:keydown={onKey} />
