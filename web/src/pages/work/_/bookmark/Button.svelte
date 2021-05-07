<script lang="ts">
  import Bookmark from 'svelte-material-icons/Bookmark.svelte'
  import BookmarkOutline from 'svelte-material-icons/BookmarkOutline.svelte'
  import Create from './Modal.svelte'
  import Modal, { openModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  import { query, operationStore } from '@urql/svelte'
  import { fade } from 'svelte/transition'

  import {
    px,
    requestError,
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
    internalErrorNotification,
  } from '$/lib'
  import { notify, Spinner } from '$/components'
  import { IS_BOOKMARKED } from '$/graphql/queries'

  import { removeBookmark } from '.'
  import { getReader } from '..'

  const { work, currentlyBookmarking } = getReader()

  $: workID = $work.workID

  const bookmarked = query(operationStore(IS_BOOKMARKED, { workID }))

  $: $bookmarked.variables!.workID = workID

  // TODO: Fix status not updating
  let isBookmarked = false
  let allowBookmarking = false

  $: if ($bookmarked.error) {
    allowBookmarking = false

    const err = requestError($bookmarked.error)

    notify({
      status: 'error',
      message: `Eroare la obținerea marcajelor: ${err.message.toLocaleLowerCase('ro-RO')}`,
      explanation: err.explanation,
    })
  } else if ($bookmarked.data) {
    allowBookmarking = true
    isBookmarked = $bookmarked.data.bookmarks.length === 1
  } else {
    allowBookmarking = false
  }

  const bookmarkHandler = async () => {
    $currentlyBookmarking = true
    await openModal(workID)
    $currentlyBookmarking = false
  }

  const removeBookmarkHandler = () =>
    removeBookmark(workID)
      .then(() => {
        notify({
          status: 'success',
          message: 'Marcajul a fost șters cu succes!',
        })
      })
      .catch(() => notify(internalErrorNotification))

  function onClick() {
    if ($currentlyBookmarking) {
      return
    }

    if (isBookmarked) {
      removeBookmarkHandler()
    } else {
      bookmarkHandler()
    }
  }

  function onKeyup({ code }: KeyboardEvent) {
    if (code !== 'KeyB') {
      return
    }

    onClick()
  }

  const size = px(1.4)
</script>

<button
  class="align-middle"
  disabled={!allowBookmarking}
  title="Salvează lucrarea"
  on:click={onClick}
  transition:fade={{ easing, duration }}>
  {#if isBookmarked}
    <Bookmark {size} />
  {:else if allowBookmarking}
    <BookmarkOutline {size} />
  {:else if !$bookmarked.error}
    <Spinner size="1.4em" />
  {/if}
</button>

<Modal let:payload>
  {#if payload}
    <Create workID={payload} />
  {/if}
</Modal>

<svelte:window on:keyup={onKeyup} />
