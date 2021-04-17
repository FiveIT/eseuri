<script lang="ts">
  import Link from './Link.svelte'
  import LayoutContext from './LayoutContext.svelte'

  import { text } from '$/theme'

  export let big = false
</script>

<LayoutContext let:theme>
  <Link href="/" on:navigate>
    <h1
      class="font-serif text-{big ? 'xl' : 'lg'} font-bold {text[
        theme
      ]} subpixel-antialiased">
      Eseuri<span class="text-orange">.</span>
    </h1>
  </Link>
</LayoutContext>
