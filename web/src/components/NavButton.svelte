<script lang="ts">
  import Link from './Link.svelte'
  import LayoutContext from './LayoutContext.svelte'

  import { isActive } from '@roxi/routify'

  import { text, filterShadow } from '$/theme'

  export let href = '/'
  export let enable = !$isActive(href)
  export let hideIfDisabled = false
</script>

{#if !hideIfDisabled || enable}
  <LayoutContext let:theme>
    <Link {href} {enable}>
      <div
        class="w-full h-full flex justify-center items-center font-sans no-underline text-sm {text[
          theme
        ]} {filterShadow[theme]}">
        <slot />
      </div>
    </Link>
  </LayoutContext>
{/if}
