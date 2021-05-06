<script lang="ts">
  import LayoutContext from './LayoutContext.svelte'
  import { text, filterShadow } from '$/lib/theme'
  import BookmarkModel from './BookmarkModel.svelte'
  import { bookmarks } from '$/content'
  let todelete: boolean
  $: if (todelete == true) {
    todelete = false
    bookmarks.splice(position)
    console.log(position)
  }
  let position: number
</script>

<LayoutContext let:theme>
  <div
    class=" z-10 {text[theme]} {filterShadow[
      theme
    ]}   col-start-1 col-span-6 row-start-5 grid grid-cols-6 h-full gap-x-md gap-y-sm mt-sm">
    <div class="col-start-1 row-start-1 text-center my-auto ">Tip</div>
    <div class="col-start-2 col-span-2 row-start-1 text-center my-auto">
      Denumire marcaj
    </div>
    <div class="col-start-4 col-span-2 row-start-1 text-center my-auto ">
      Subiect
    </div>
    <div class="col-start-6 row-start-1 text-center my-auto ">
      Timpul salvarii
    </div>
  </div>
  <div class="row-start-6 col-span-6 {text[theme]} {filterShadow[theme]}">
    {#each bookmarks as bookmark, i}
      <BookmarkModel
        name={bookmark.bookmarkname}
        type={bookmark.type}
        subiect={bookmark.subject}
        time={bookmark.time}
        {todelete}
        {i}
        bind:position />
    {/each}
  </div>
</LayoutContext>
