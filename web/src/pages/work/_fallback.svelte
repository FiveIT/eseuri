<script lang="ts">
  import { getLayout } from '$/components/Layout.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { Reader, Spinner, works, notify, internalErrorNotification, defaultWorkData } from './_'
  import type { Work } from './_'

  import { isWorkType } from '$/lib/types'

  import { onDestroy } from 'svelte'
  import { goto, leftover, metatags } from '@roxi/routify'

  const { red: setRedBlob, autoSet } = getLayout().blobs
  let work: Work
  let done = false
  let show = false
  let notFoundParagraphs = [
    'Am primit niște date incorecte și nu-ți putem afișa vreo lucrare.',
    `Cel mai probabil ai ajuns aici din greșeală, <a class="underline" href="/search">caută ceva</a> sau <a class="underline" href="/upload">încarcă o lucrare</a>!`,
  ]

  $: $autoSet = !done || show
  $: done &&
    !show &&
    setRedBlob({
      rotate: 47,
      scale: 2,
      x: $window.width - red.width * 2,
      y: $window.height + 40,
    })

  onDestroy(() => ($autoSet = true))

  const [type, title, workID] = $leftover.split('/')

  let pageTitle = 'Lucrări - Eseuri'

  $: metatags.title = pageTitle

  if (!type || !title || !isWorkType(type)) {
    done = true
  } else {
    works(title, type, workID)
      .then(works => {
        if (!works) {
          notFoundParagraphs = [
            'Subiectul căutat de tine nu este la noi pe platformă.',
            'Dacă ai ajuns aici din greșeală, folosește bara de navigare pentru a ieși de aici.',
            'Dacă ai căutat intenționat acest subiect și crezi că ar trebui să existe pe platformă, <a class="underline" href="mailto:tmaxmax@outlook.com">scrie-ne un email</a>!',
          ]

          return
        }

        const { id, name } = works

        if (!works.found) {
          notFoundParagraphs = [
            'Nu există lucrări încărcate pentru acest subiect.',
            'Însă poți tu să ai primul inițiativa! Încărcând lucrări, îți dezvolți abilitățile pentru subiectul al III-lea de la bacalaureat și îi ajuți pe ceilalți colegi, lucrând împreună la un scop comun!',
            `<a class="underline" href="/upload?id=${id}&type=${type}">Încarcă o lucrare cu subiectul "${name}"</a>.`,
          ]

          return
        }

        const it = works[Symbol.asyncIterator]()

        work = {
          title: name,
          data: Promise.resolve(defaultWorkData),
          next() {
            this.data = it.next().then(v => {
              const data = v.value

              $goto(`/work/${type}/${title}/${data.id}`)

              pageTitle = `${name} - Lucrări - Eseuri`

              return data
            })
          },
          prev() {
            const res = it.prev()
            this.data = res.then(r => {
              const data = r.value!

              $goto(`/work/${type}/${title}/${data.id}`)

              pageTitle = `${name} - Lucrări - Eseuri`

              return data
            })

            return res.then(r => !!r.done)
          },
        }

        work.next()

        show = true
      })
      .catch(err => {
        console.error(err)

        notify(internalErrorNotification)
      })
      .finally(() => (done = true))
  }
</script>

{#if done && show}
  <Reader {work} />
{:else if done}
  <div class="flex flex-col col-start-2 col-span-4 text-center">
    <h2 class="font-serif text-title antialiased mb-md">Ups!</h2>
    {#each notFoundParagraphs as text}
      <p class="text-sm font-sans mt-sm antialiased leading-tight mx-auto max-w-1/2">
        {@html text}
      </p>
    {/each}
  </div>
{:else}
  <div class="col-span-6 row-start-4">
    <Spinner message="Se încarcă lucrarea ta..." />
  </div>
{/if}
