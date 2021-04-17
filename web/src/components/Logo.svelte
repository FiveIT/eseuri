<script lang="ts">
  import Link from './Link.svelte'

  import { contextKey } from './Layout.svelte'
  import type { Context } from './Layout.svelte'

  import { text } from '$/theme'

  import { getContext } from 'svelte'

  const { theme } = getContext<Context>(contextKey)
</script>

<Link href="/">
  <h1 class="font-serif text-lg font-bold {text[$theme]} subpixel-antialiased">
    Eseuri<span class="text-orange">.</span>
  </h1>
</Link>
