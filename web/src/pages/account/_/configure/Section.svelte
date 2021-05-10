<script lang="ts">
  import { filterShadow, text } from '$/lib'
  import { LayoutContext } from '$/components'
</script>

<LayoutContext let:theme>
  <section
    class="row-span-3 col-span-3 grid grid-cols-1 auto-rows-layout gap-y-sm font-sans text-sm {text[
      theme
    ]} {filterShadow[theme]}">
    <slot />
  </section>
</LayoutContext>
