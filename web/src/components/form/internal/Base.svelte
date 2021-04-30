<script>
  import LayoutContext from '../../LayoutContext.svelte'
</script>

<LayoutContext let:theme>
  <div class="grid gap-x-md auto-cols-layout grid-flow-col text-sm font-sans">
    <slot {theme} />
  </div>
</LayoutContext>
