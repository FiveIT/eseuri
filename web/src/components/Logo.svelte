<script lang="ts">
  import { text } from '$/lib/theme'
  import LayoutContext from './LayoutContext.svelte'
  import Link from './Link.svelte'

  export let big = false
</script>

<LayoutContext let:theme>
  <Link href="/" on:navigate let:disable>
    <h1
      class="font-serif text-{big ? 'xl' : 'lg'} font-bold {text[theme]} antialiased select-none"
      class:cursor-default={disable}>
      Eseuri<span class="text-orange">.</span>
    </h1>
  </Link>
</LayoutContext>
