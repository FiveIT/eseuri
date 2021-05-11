<script>
  import NavButton from './internal/NavButton.svelte'
  import { getLayout } from '$/components'

  const { theme: themeStore } = getLayout()

  export let theme = $themeStore
</script>

<NavButton title="Caută o lucrare" {theme} href="/search" hideIfDisabled on:navigate
  >Căutare</NavButton>
