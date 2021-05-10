<script context="module" lang="ts">
  const colors = {
    default: 'black',
    white: 'white',
  }
</script>

<script lang="ts">
  import Icon from 'svelte-material-icons/Close.svelte'

  import { px, border } from '$/lib'
  import { LayoutContext } from '$/components'
</script>

<LayoutContext let:theme>
  <button
    class="rounded-full w-2em h-2em border-1 {border.color[
      theme
    ]} opacity-0 group-hover:opacity-100 focus:opacity-100 group-focus:opacity-100 flex items-center justify-center z-1"
    on:click>
    <Icon color="var(--{colors[theme]})" size={px(2)} />
  </button>
</LayoutContext>
