<script lang="ts">
  import { getContext } from 'svelte'
  import type { Context } from '$/pages/essays/[page_name].svelte'
  import Bookmark from 'svelte-material-icons/Bookmark.svelte'
  import BookmarkOutline from 'svelte-material-icons/BookmarkOutline.svelte'
  import { contextKey } from '$/pages/essays/[page_name].svelte'
  import { px } from '$/util'
  import BookmarkCreation from './BookmarkCreation.svelte'

  const ctx = getContext<Context>(contextKey)
  console.log(ctx)
  let show = false
  const size = px(1.4)
</script>

<button
  class="align-middle"
  on:click={() => {
    $ctx.saved ? ctx.unsave() : ctx.save(), (show = !show)
  }}>
  {#if $ctx.saved}
    <Bookmark {size} />
  {:else}
    <BookmarkOutline {size} />
  {/if}
</button>
{#if show}
  <BookmarkCreation show={$ctx.saved} />
{/if}
