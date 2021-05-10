<script lang="ts">
  import { fitText, BaseLayout } from '.'
  import { px } from '$/lib'
  import type { Theme } from '$/lib'

  export let theme: Theme | undefined = undefined
  export let borderColor: string | undefined = undefined
  export let darkBg = false
  export let showOverlay = false
</script>

<BaseLayout {theme} {borderColor} {darkBg}>
  <dl class="grid w-full grid-flow-row h-full grid-rows-4 gap-y-xs">
    <dt
      class="row-span-2 h-full flex flex-col"
      use:fitText={{ min: parseInt(px(1.5)), max: parseInt(px(1.75)) }}>
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
        class="absolute w-full h-full top-0 left-0 duration-50 transition-opacity ease-out opacity-0 group-hover:opacity-100 group-focus:opacity-100">
        <slot name="overlay" />
      </div>
    {/if}
  </dl>
</BaseLayout>
