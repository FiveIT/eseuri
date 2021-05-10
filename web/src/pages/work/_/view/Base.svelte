<script lang="ts" context="module">
  const getParagraphs = (text: string) =>
    text
      .trim()
      .split(/(?:\r?\n)+/)
      .map(p => p.trim())
</script>

<script lang="ts">
  import type { WorkBase } from '..'
  import { Spinner, Link } from '$/components'
  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
    workTypeTranslation,
    title,
    px,
  } from '$/lib'
  import { fade } from 'svelte/transition'
  import { params } from '@roxi/routify'
  import ArrowBack from 'svelte-material-icons/ArrowLeft.svelte'

  export let work: WorkBase
  export let additionalHeadingText = ''
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
      <p class="text-sm font-sans antialiased">
        {title(workTypeTranslation.ro[work.type].inarticulate.singular)}
        {additionalHeadingText}
      </p>
      <div class="w-min">
        <div class="flex space-x-sm">
          <slot name="heading" />
          {#if $params.back}
            <Link href={atob($params.back)} title="Întoarce-te de unde ai venit">
              <ArrowBack size={px(1.4)} color="var(--black)" />
            </Link>
          {/if}
        </div>
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
