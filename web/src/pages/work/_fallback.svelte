<script lang="ts">
  import { getLayout } from '$/components/Layout.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Spinner from '$/components/Spinner.svelte'
  import { Reader, Notifications } from './_'

  import { isWorkType } from '$/lib/types'

  import { onDestroy } from 'svelte'
  import { leftover } from '@roxi/routify'

  const { red: setRedBlob, autoSet } = getLayout().blobs
  let notFound = false
  let show = false
  let notFoundParagraphs: string[]
  let work: {
    title: string
    content: string
    next(): void
    prev(): void
  }

  $: notFound &&
    setRedBlob({
      rotate: 47,
      scale: 2,
      x: $window.width - red.width * 2,
      y: $window.height + 40,
    })

  onDestroy(() => ($autoSet = true))

  const [type, title, id] = $leftover.split('/')

  if (!type || !title || !isWorkType(type)) {
    notFoundParagraphs = [
      'Această pagină nu există!',
      'Folosește bara de navigare pentru a ieși de aici.',
    ]

    notFound = true
  } else {
    notFoundParagraphs = [
      'Subiectul căutat de tine nu este la noi pe platformă.',
      'Dacă ai ajuns aici din greșeală, folosește bara de navigare pentru a ieși de aici.',
      'Dacă ai căutat intenționat acest subiect și crezi că ar trebui să existe pe platformă, <a class="underline" href="mailto:tmaxmax@outlook.com">scrie-ne un email</a>!',
    ]
  }
</script>

{#if show}
  <Reader {...work} />
{:else if notFound}
  <div class="flex flex-col col-start-2 col-span-4 text-center">
    <h2 class="font-serif text-title antialiased mb-md">Ups! Această lucrare nu există.</h2>
    {#each notFoundParagraphs as text}
      <p class="text-sm font-sans mt-sm antialiased leading-none mx-auto max-w-1/2">
        {@html text}
      </p>
    {/each}
  </div>
{:else}
  <div class="col-span-6 row-start-4">
    <Spinner message="Se încarcă lucrarea ta.." />
  </div>
{/if}
<Notifications />
