<script lang="ts" context="module">
  const getParagraphs = (text: string) =>
    text
      .trim()
      .split(/(?:\r?\n)+/)
      .map(p => p.trim())
</script>

<script lang="ts">
  import type { WorkBase } from '..'
  import { Spinner } from '$/components'
  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
    workTypeTranslation,
    title,
  } from '$/lib'
  import { fade } from 'svelte/transition'

  export let work: WorkBase
  // eslint-disable-next-line no-unused-vars
  export let transitionFn: (...args: any[]) => any = fade
  export let transitionProps: any = { duration, easing }
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
        <slot name="heading" />
      </div>
    </div>
  </header>
  {#await work.data}
    <div class="col-span-6 flex justify-center items-center my-lg">
      <Spinner />
    </div>
  {:then { content }}
    <main
      class="mt-lg space-y-sm"
      in:fade={{ duration, easing, delay: duration }}
      out:transitionFn={transitionProps}>
      {#each getParagraphs(content) as paragraph}
        <p class="text-prose font-serif antialiased">
          {paragraph}
        </p>
      {/each}
    </main>
  {:catch}
    <p class="mt-lg text-gray font-sans text-md antialiased">
      Nu am reușit să obținem lucrarea, revino mai târziu.
    </p>
  {/await}
</article>
<slot />
<aside class="col-start-2">
  <slot name="footer" />
</aside>
