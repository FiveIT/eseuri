<script lang="ts">
  import Cross from 'svelte-material-icons/Plus.svelte'
  import { isActive } from '@roxi/routify'
  import Link from './internal/Link.svelte'
  import { px } from '$/lib'

  $: disable = $isActive('/upload_configure')
</script>

<Link href="/upload" on:navigate {disable} hideIfDisabled title="Încarcă o lucrare">
  <div class="bg-orange p-md rounded-full w-min filter-shadow">
    <Cross size={px(2)} color="var(--white)" />
  </div>
</Link>
