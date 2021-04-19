<script lang="ts">
  import { getContext } from 'svelte'
  import type { Context } from '$/pages/essays/[page_name].svelte'
  import Bookmark from 'svelte-material-icons/Bookmark.svelte'
  import BookmarkOutline from 'svelte-material-icons/BookmarkOutline.svelte'
  import { contextKey } from '$/pages/essays/[page_name].svelte'
  import { px } from '$/util'

  const ctx = getContext<Context>(contextKey)
  console.log(ctx)

  const size = px(1.4)
</script>

<button
  class="align-middle"
  on:click={() => ($ctx.saved ? ctx.unsave() : ctx.save())}>
  {#if $ctx.saved}
    <Bookmark {size} />
  {:else}
    <BookmarkOutline {size} />
  {/if}
</button>
