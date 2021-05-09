<script lang="ts">
  import { getLayout } from '$/components'
  import { text, border, filterShadow, fontWeight } from '$/lib'
  import { fitText } from '.'
  import type { Theme } from '$/lib'

  const { theme: themeStore } = getLayout()

  export let theme: Theme | undefined = undefined
  export let borderColor: string | undefined = undefined
  export let darkBg = false
  export let showOverlay = false

  $: t = theme ? theme : $themeStore
  $: b = borderColor ? borderColor : border.color[t]
</script>

<dl
  class="group relative grid w-full grid-flow-row h-full grid-rows-4 gap-y-xs px-sm py-xs font-sans antialiased rounded leading-none {text[
    t
  ]} {b} {border.size[t]} {filterShadow[t]} {fontWeight[t]}"
  class:white-bg={t === 'default'}
  class:blur={t === 'default'}
  class:darkBg>
  <dt class="row-span-2 h-full flex flex-col" use:fitText={{ compensation: 1.1 }}>
    <slot name="heading" />
  </dt>
  <dt class="self-center h-full flex flex-col" use:fitText>
    <slot name="middle" />
  </dt>
  <dt use:fitText>
    <slot name="end" />
  </dt>
  {#if showOverlay}
    <div
      class="absolute w-full h-full duration-50 transition-opacity ease-out opacity-0 group-hover:opacity-100 group-focus:opacity-100">
      <slot name="overlay" />
    </div>
  {/if}
</dl>

<style>
  dl.darkBg {
    background-color: rgba(0, 0, 0, 0.1);
  }
</style>
