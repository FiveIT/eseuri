<script lang="ts">
  import Cross from 'svelte-material-icons/Plus.svelte'
  import Link from './Link.svelte'
</script>

<Link href="/upload">
  <button class="bg-orange rounded-full m-auto">
    <div class="mx-auto my-auto">
      <div class="mx-auto w-min h-min fill-white">
        <Cross size="2rem" />
      </div>
    </div>
  </button>
</Link>

<style>
  button {
    width: calc(var(--l_row) * 1.08);
    height: calc(var(--l_row) * 1.08);
    filter: drop-shadow(var(--shadow));
  }
</style>
