<script lang="ts">
  import Link from './link.svelte'
  import Cross from 'svelte-material-icons/Plus.svelte'
  export let link: string
  export let alive: boolean
</script>

<Link href={link} bind:alive>
  <button
    class="bg-orange rounded-full m-auto focus:outline-none outline-none focus:md:underline">
    <div class="mx-auto my-auto">
      <div class="mx-auto w-min h-min">
        <Cross size="2rem" color="white" />
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
