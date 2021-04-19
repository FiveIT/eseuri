<script lang="ts">
  import Orange from '$/components/blob/Orange.svelte'
  import Red from '$/components/blob/Red.svelte'
  import Blue from '$/components/blob/Blue.svelte'

  import { setContext } from 'svelte'
  import { contextKey } from '$/pages/upload.svelte'
  import type { Context } from '$/pages/upload.svelte'

  setContext<Context>(contextKey, {
    file: null,
  })
</script>

<Orange />
<Red />
<Blue />
<slot />
