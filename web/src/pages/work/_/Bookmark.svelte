<script lang="ts">
  import Bookmark from 'svelte-material-icons/Bookmark.svelte'
  import { px } from '$/lib/util'

  const size = px(1.4)
</script>

<button class="align-middle" on:click={() => {}}>
  <Bookmark {size} />
</button>
