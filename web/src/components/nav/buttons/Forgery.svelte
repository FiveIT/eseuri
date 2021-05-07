<script>
  import NavButton from './internal/NavButton.svelte'
  import { getLayout } from '$/components'

  const { theme: themeStore } = getLayout()

  export let theme = $themeStore
</script>

<NavButton
  disable
  showTooltip
  {theme}
  title="În viitor - verifică originalitatea lucrării"
  on:navigate>Plagiat</NavButton>
