<script>
  import { LayoutContext } from '$/components'
  import { placeholderText } from '$/lib'

</script>

<LayoutContext let:theme>
  <p class="col-start-4 col-span-3 row-span-2 text-md text-center {placeholderText[theme]}">
    <slot />
  </p>
</LayoutContext>
