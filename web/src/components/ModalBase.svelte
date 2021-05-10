<script>
  import { fade } from 'svelte/transition'
  import { TRANSITION_EASING as easing, border, background } from '$/lib'
  import { closeModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'
  import { LayoutContext } from '$/components'

</script>

<LayoutContext let:theme>
  <div
    class="bg fixed top-0 left-0 w-full h-full flex justify-center items-center z-100"
    transition:fade={{ easing, duration: 50 }}>
    <div
      class="grid gap-x-md gap-y-sm px-md py-sm grid-cols-form auto-rows-layout rounded {background[
        theme
      ]} {border.color[theme]} {border.all[theme]}"
      on:blur={closeModal}>
      <slot />
    </div>
  </div>
</LayoutContext>

<style>
  .bg {
    background-color: rgba(0, 0, 0, 0.5);
  }

</style>
