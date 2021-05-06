<script>
  import NavButton from '../NavButton.svelte'
  import { getLayout } from '../Layout.svelte'

  const { theme: themeStore } = getLayout()

  export let theme = $themeStore
</script>

<NavButton
  disable
  showTooltip
  title="În viitor - vezi toți profesorii de pe Eseuri"
  {theme}
  on:navigate>Profesori</NavButton>
