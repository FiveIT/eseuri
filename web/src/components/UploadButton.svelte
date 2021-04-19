<script lang="ts">
  import Cross from 'svelte-material-icons/Plus.svelte'
  import Link from './Link.svelte'

  import { isActive } from '@roxi/routify'

  import { px } from '$/util'

  $: isUploadConfigure = $isActive('/upload_configure', undefined, {
    strict: false,
  })
</script>

<Link
  href="/upload"
  enable={!isUploadConfigure}
  hideIfDisabled={isUploadConfigure}
  on:navigate>
  <div class="bg-orange p-md rounded-full w-min filter-shadow">
    <Cross size={px(2)} color="var(--white)" />
  </div>
</Link>
