<script lang="ts">
  import Link from './Link.svelte'
  export let link: string
  export let alive: boolean
</script>

<Link href={link} bind:alive>
  <button
    class="bg-orange rounded-full m-auto focus:outline-none outline-none focus:md:underline">
    <div class="mx-auto my-auto">
      <svg
        width="18"
        height="18"
        viewBox="0 0 18 18"
        fill="none"
        class="mx-auto my-auto"
        xmlns="http://www.w3.org/2000/svg">
        <path
          d="M18 10.2857H10.2857V18H7.71429V10.2857H0V7.71429H7.71429V0H10.2857V7.71429H18V10.2857Z"
          fill="#FCFAF9" />
      </svg>
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
