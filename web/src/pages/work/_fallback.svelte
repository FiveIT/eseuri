<script lang="ts">
  import { getLayout, window, red, notify, Spinner } from '$/components'
  import { isWorkType, internalErrorNotification } from '$/lib'
  import type { WorkType } from '$/lib'
  import type { Relay } from '$/graphql/queries'
  import { Read, Review, works, defaultWorkData, unrevisedWork } from './_'
  import { bookmark, isBookmarked, removeBookmark } from './_/bookmark'
  import type { Work } from './_'

  import { onDestroy } from 'svelte'
  import { goto, leftover, metatags } from '@roxi/routify'
  import { writable } from 'svelte/store'
  import { isAuthenticated } from '@tmaxmax/svelte-auth0'

  const { red: setRedBlob, autoSet } = getLayout().blobs
  let w: (Work & { setBookmarked(): void }) | undefined
  let uw: ReturnType<typeof unrevisedWork> | undefined
  let noMatch = false
  let notFoundParagraphs = [
    'Am primit niște date incorecte și nu-ți putem afișa vreo lucrare.',
    `Cel mai probabil ai ajuns aici din greșeală, <a class="underline" href="/search">caută ceva</a> sau <a class="underline" href="/upload">încarcă o lucrare</a>!`,
  ]

  $: $autoSet = !noMatch || !!w
  $: noMatch &&
    !w &&
    setRedBlob({
      rotate: 47,
      scale: 2,
      x: $window.width - red.width * 2,
      y: $window.height + 40,
    })
  $: w && $isAuthenticated && w.setBookmarked()
  $: if (uw && $uw === null) {
    noMatch = true
  }

  onDestroy(() => ($autoSet = true))

  const [type, title, workID] = $leftover.split('/')

  let pageTitle = 'Lucrări - Eseuri'

  $: metatags.title = pageTitle

  const setWork = (title: string, type: WorkType, workID?: Relay.ID) =>
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

        const bookmarkedWorks: Record<Relay.ID, string> = {}

        w = {
          title: name,
          type,
          data: Promise.resolve(defaultWorkData),
          setBookmarked(force?: boolean) {
            if ($isAuthenticated) {
              this.data
                .then(w => {
                  if (bookmarkedWorks[w.id]) {
                    return bookmarkedWorks[w.id]
                  }

                  return isBookmarked(w.workID, force)
                })
                .then(is => this.bookmarked.set(is))
            }
          },
          next() {
            this.bookmarked.set(null)

            this.data = it.next().then(v => {
              const data = v.value

              $goto(`/work/${type}/${title}/${data.id}`)

              pageTitle = `${name} - Lucrări - Eseuri`

              return data
            })

            this.setBookmarked()
          },
          prev() {
            this.bookmarked.set(null)

            const res = it.prev()
            this.data = res.then(r => {
              const data = r.value!

              $goto(`/work/${type}/${title}/${data.id}`)

              pageTitle = `${name} - Lucrări - Eseuri`

              return data
            })

            this.setBookmarked()

            return res.then(r => !!r.done)
          },
          bookmarked: writable(null),
          async bookmark(name: string) {
            const { id, workID } = await this.data
            await bookmark(workID, name)
            this.bookmarked.set(name)

            bookmarkedWorks[id] = name
          },
          async removeBookmark() {
            const { id, workID } = await this.data
            await removeBookmark(workID)
            this.bookmarked.set('')

            if (bookmarkedWorks[id]) {
              bookmarkedWorks[id] = ''
              delete bookmarkedWorks[id]
            }
          },
        }

        w.next()
      })
      .catch(err => {
        console.error(err)

        notify(internalErrorNotification)
      })
      .finally(() => (noMatch = true))

  if (type) {
    const id = parseInt(type)

    if (id) {
      uw = unrevisedWork(id)
    } else if (isWorkType(type)) {
      setWork(title, type, workID)
    } else {
      noMatch = true
    }
  } else {
    noMatch = true
  }
</script>

<!-- TODO: Reader for review -->
{#if w}
  <Read work={w} />
{:else if uw && $uw}
  <Review work={$uw} />
{:else if noMatch}
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
