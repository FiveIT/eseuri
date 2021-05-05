<script lang="ts">
  import { text } from '$/theme'
  import LayoutContext from './LayoutContext.svelte'
  import Link from './Link.svelte'

  export let big = false
</script>

<LayoutContext let:theme>
  <div class="z-10">
    <Link href="/" on:navigate let:enable>
      <h1
        class="font-serif text-{big ? 'xl' : 'lg'} font-bold {text[
          theme
        ]} antialiased z-10 "
        class:cursor-default={!enable}>
        Eseuri<span class="text-orange">.</span>
      </h1>
    </Link>
  </div>
</LayoutContext>
