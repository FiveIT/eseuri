<script>
  import NavButton from '../NavButton.svelte'
  import { getLayout } from '../Layout.svelte'

  const { theme: themeStore } = getLayout()

  export let theme = $themeStore
</script>

<NavButton
  disable
  showTooltip
  {theme}
  title="În viitor - verifică originalitatea lucrării"
  on:navigate>Plagiat</NavButton>
