<script lang="ts">
  import { Spinner } from '$/components'
  import { getTable, register } from '.'

  const { rows } = getTable()

  register(rows, 2)
</script>

<div class="col-span-full flex justify-center items-center row-span-2"><Spinner /></div>
