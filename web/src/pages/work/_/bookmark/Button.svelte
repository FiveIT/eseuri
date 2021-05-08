<script lang="ts">
  import Bookmark from 'svelte-material-icons/Bookmark.svelte'
  import BookmarkOutline from 'svelte-material-icons/BookmarkOutline.svelte'
  import Create from './Modal.svelte'
  import Modal, { openModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  import { fade } from 'svelte/transition'

  import {
    px,
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
    internalErrorNotification,
  } from '$/lib'
  import { notify, Spinner } from '$/components'

  import { getReader } from '..'

  const { work, currentlyBookmarking } = getReader()

  $: bookmarkStore = $work?.bookmarked
  $: isBookmarked = !!bookmarkStore && $bookmarkStore !== null && $bookmarkStore
  $: loading = !bookmarkStore || $bookmarkStore === null

  const bookmarkHandler = async () => {
    $currentlyBookmarking = true
    await openModal($work!)
    $currentlyBookmarking = false
  }

  const removeBookmarkHandler = () => {
    $work!
      .removeBookmark()
      .then(() =>
        notify({
          status: 'success',
          message: 'Lucrarea nu mai este salvată!',
        })
      )
      .catch(() =>
        notify({
          ...internalErrorNotification,
          message: `Eroare la anularea salvării lucrării: ${internalErrorNotification.message.toLocaleLowerCase(
            'ro-RO'
          )}`,
        })
      )
  }

  function onClick() {
    if (loading) {
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

  const emSize = 1.4
  const size = px(emSize)
</script>

<button
  class="align-middle"
  class:cursor-default={loading}
  disabled={loading}
  title={loading
    ? undefined
    : isBookmarked
    ? `Anulează salvarea "${isBookmarked}"`
    : 'Salvează lucrarea'}
  on:click={onClick}
  transition:fade={{ easing, duration }}>
  {#if loading}
    <Spinner size="{emSize}em" longDuration={null} />
  {:else if isBookmarked}
    <Bookmark {size} />
  {:else}
    <BookmarkOutline {size} />
  {/if}
</button>

<Modal let:payload>
  {#if payload}
    <Create work={payload} />
  {/if}
</Modal>

<svelte:window on:keyup={onKeyup} />
