<script>
  import NavButton from './internal/NavButton.svelte'
  import { getLayout } from '$/components'

  const { theme: themeStore } = getLayout()

  export let theme = $themeStore
</script>

<NavButton
  disable
  showTooltip
  title="În viitor - vezi toți profesorii de pe Eseuri"
  {theme}
  on:navigate>Profesori</NavButton>
