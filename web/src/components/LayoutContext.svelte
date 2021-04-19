<script lang="ts">
  import { getContext } from 'svelte'

  import { contextKey } from './Layout.svelte'
  import type { Context } from './Layout.svelte'

  const { theme, alive } = getContext<Context>(contextKey)
</script>

<slot theme={$theme} {alive} />
