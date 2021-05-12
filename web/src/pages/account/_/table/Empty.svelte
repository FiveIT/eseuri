<script>
  import { LayoutContext } from '$/components'
  import { placeholderText } from '$/lib'
  import { getTable } from './Table.svelte'
  import { register } from '.'

  register(getTable().rows)

</script>

<LayoutContext let:theme>
  <p class="col-span-full text-center text-md font-sans antialiased {placeholderText[theme]}">
    <slot />
  </p>
</LayoutContext>
