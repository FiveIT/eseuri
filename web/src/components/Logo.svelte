<script lang="ts">
  import Link from './Link.svelte'
  import LayoutContext from './LayoutContext.svelte'

  import { text } from '$/theme'
</script>

<LayoutContext let:theme>
  <Link href="/">
    <h1 class="font-serif text-lg font-bold {text[theme]} subpixel-antialiased">
      Eseuri<span class="text-orange">.</span>
    </h1>
  </Link>
</LayoutContext>
