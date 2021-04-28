<script lang="ts">
  import { getLayout } from './Layout.svelte'

  const { theme, alive } = getLayout()
</script>

<slot theme={$theme} {alive} />
