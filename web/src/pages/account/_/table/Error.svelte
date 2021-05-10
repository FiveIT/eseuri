<script lang="ts">
  import { getTable, register } from '.'

  import { LayoutContext } from '$/components'
  import { placeholderText } from '$/lib'

  const { rows } = getTable()

  register(rows)
</script>

<LayoutContext let:theme>
  <p class="col-span-full place-self-center text-md text-center {placeholderText[theme]}">
    <slot>A apărut o eroare, revino mai târziu.</slot>
  </p>
</LayoutContext>
