<script>
  import { fade } from 'svelte/transition'
  import { TRANSITION_EASING as easing } from '$/lib'
  import { LayoutContext } from '$/components'
</script>

<LayoutContext let:theme>
  <div
    class="bg fixed top-0 left-0 w-full h-full flex justify-center items-center z-100"
    transition:fade={{ easing, duration: 50 }}>
    <slot {theme} />
  </div>
</LayoutContext>

<style>
  .bg {
    background-color: rgba(0, 0, 0, 0.5);
  }
</style>
