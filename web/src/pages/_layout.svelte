<script lang="ts" context="module">
  import { getContext, setContext } from 'svelte'
  import { writable } from 'svelte/store'
  import type { Writable } from 'svelte/store'

  import type { Theme } from '$/lib'

  const themeContextKey = {}

  export function getTheme(): Writable<Theme> {
    return getContext(themeContextKey)
  }

  function setTheme() {
    setContext(themeContextKey, writable('default'))
  }
</script>

<script lang="ts">
  import { Orange, Red, Blue, Notifications } from '$/components'

  import { contextKey } from '$/pages/upload.svelte'
  import type { Context } from '$/pages/upload.svelte'

  setContext<Context & { theme: Writable<Theme> }>(contextKey, {
    file: null,
    theme: writable('default'),
  })

  setTheme()
</script>

<Orange />
<Red />
<Blue />
<slot />
<Notifications />
