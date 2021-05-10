<script lang="ts">
  import { getLayout } from '$/components'
  import { text, border, filterShadow, fontWeight } from '$/lib'
  import type { Theme } from '$/lib'

  const { theme: themeStore } = getLayout()

  export let theme: Theme | undefined = undefined
  export let borderColor: string | undefined = undefined
  export let darkBg = false

  $: t = theme ? theme : $themeStore
  $: b = borderColor ? borderColor : border.color[t]
</script>

<div
  class="group relative w-full h-full px-sm py-xs font-sans antialiased rounded leading-none {text[
    t
  ]} {b} {border.all[t]} {filterShadow[t]} {fontWeight[t]}"
  class:white-bg={t === 'default'}
  class:blur={t === 'default'}
  class:darkBg>
  <slot theme={t} />
</div>

<style>
  div.darkBg {
    background-color: rgba(0, 0, 0, 0.1);
  }
</style>
