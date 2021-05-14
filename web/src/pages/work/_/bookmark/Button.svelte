<script lang="ts">
  import { bookmark, removeBookmark } from '../view/Read.svelte'

  import Bookmark from 'svelte-material-icons/Bookmark.svelte'
  import BookmarkOutline from 'svelte-material-icons/BookmarkOutline.svelte'

  import { fade } from 'svelte/transition'

  import { px, TRANSITION_EASING as easing, TRANSITION_DURATION as duration } from '$/lib'
  import { Spinner } from '$/components'

  import { getReader } from '..'

  const { work, currentlyBookmarking } = getReader()

  $: bookmarkStore = $work?.bookmarked
  $: isBookmarked = !!bookmarkStore && $bookmarkStore !== null && $bookmarkStore
  $: loading = !bookmarkStore || $bookmarkStore === null

  function onClick() {
    if (loading || !$work) {
      return
    }

    if (isBookmarked) {
      removeBookmark($work)
    } else {
      bookmark($work, currentlyBookmarking)
    }
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
