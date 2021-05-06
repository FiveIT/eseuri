<script lang="ts">
  import Bookmark from 'svelte-material-icons/Bookmark.svelte'
  import BookmarkOutline from 'svelte-material-icons/BookmarkOutline.svelte'

  import { query, operationStore } from '@urql/svelte'

  import { px, requestError } from '$/lib/util'
  import { IS_BOOKMARKED } from '$/graphql/queries'

  import { bookmark, removeBookmark, getWork, notify } from '.'

  const work = getWork()

  $: workID = $work.workID

  const bookmarked = query(
    operationStore(IS_BOOKMARKED, { workID }, { requestPolicy: 'network-only' })
  )

  $: $bookmarked.variables!.workID = workID

  let isBookmarked = false
  let allowBookmarking = false

  // TODO: Create modal for bookmark name input
  const bookmarkHandler = () => {
    bookmark(workID).catch(console.error)
  }

  const removeBookmarkHandler = () => {
    removeBookmark(workID).catch(console.error)
  }

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
  }

  const size = px(1.4)
</script>

<button
  class="align-middle"
  disabled={!allowBookmarking}
  on:click={() => allowBookmarking && (isBookmarked ? removeBookmarkHandler : bookmarkHandler)()}>
  {#if isBookmarked}
    <Bookmark {size} />
  {:else}
    <BookmarkOutline {size} />
  {/if}
</button>
