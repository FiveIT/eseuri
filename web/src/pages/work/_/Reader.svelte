<script lang="ts" context="module">
  const keys: Record<'prev' | 'next', Record<string, boolean>> = {
    prev: {
      ArrowLeft: true,
      ArrowUp: true,
      KeyH: true,
      KeyK: true,
    },
    next: {
      ArrowRight: true,
      ArrowDown: true,
      KeyL: true,
      KeyJ: true,
    },
  }
</script>

<script lang="ts">
  import { Next, Back, Bookmark, Spinner, notify, internalErrorNotification } from '.'
  import type { Work } from '.'
  import { TRANSITION_EASING as easing, TRANSITION_DURATION as duration } from '$/lib/globals'
  import { fade } from 'svelte/transition'

  export let work: Work

  let prevDisabled = true

  $: p = work.content.catch(err => {
    console.error(err)

    notify(internalErrorNotification)
  })

  const update = () => {
    work = work
  }

  const next = () => {
    work.next()
    prevDisabled = false
    update()
  }

  const prev = async () => {
    if (!prevDisabled) {
      prevDisabled = !(await work.prev())
      update()
    }
  }

  function onKey({ code }: KeyboardEvent) {
    if (keys.prev[code]) {
      prev()
    } else if (keys.next[code]) {
      next()
    }
  }
</script>

<div class="col-start-2 col-end-6 row-start-3 flex flex-col space-y-sm justify-between">
  <h2 class="text-title font-serif antialiased">
    {work.title}
  </h2>
  <div class="flex justify-between align-middle">
    <div class="w-min text-sm font-sans antialiased">Eseu</div>
    <div class="w-min"><Bookmark /></div>
  </div>
  {#await p}
    <div class="col-span-6 flex justify-center items-center">
      <Spinner />
    </div>
  {:then text}
    <p class="text-prose font-serif antialiased whitespace-pre-line" in:fade={{ duration, easing }}>
      {text}
    </p>
  {/await}
</div>
<Back disabled={prevDisabled} on:click={prev} />
<Next on:click={next} />
<div class="col-start-2">
  <Bookmark />
</div>

<svelte:window on:keydown={onKey} />
