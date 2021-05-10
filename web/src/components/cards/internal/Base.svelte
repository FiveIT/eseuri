<script lang="ts">
  import { fitText, BaseLayout } from '.'

  export let showOverlay = false
</script>

<BaseLayout>
  <dl class="grid w-full grid-flow-row h-full grid-rows-4 gap-y-xs">
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
</BaseLayout>

<style>
</style>
