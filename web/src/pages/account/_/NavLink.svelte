<script lang="ts">
  import { isActive, url } from '@roxi/routify'

  export let href: string

  $: underline = $isActive(href, undefined, { strict: false })
</script>

<a href={$url(href)} class="w-auto h-auto select-none">
  <div
    class="h-full text-white text-sm flex justify-center items-center font-sans antialiased"
    class:underline>
    <slot />
  </div>
</a>
