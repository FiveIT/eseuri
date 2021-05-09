<script lang="ts">
  import type { UnrevisedWork } from '..'
  import Base from './Base.svelte'

  export let work: UnrevisedWork
</script>

<Base {work} additionalHeadingText={`de ${work.user}`} />
