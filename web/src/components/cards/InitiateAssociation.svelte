<script context="module" lang="ts">
  const colors = {
    default: 'black',
    white: 'white',
  } as const
</script>

<script lang="ts">
  import { BaseLayout } from './internal'
  import Icon from 'svelte-material-icons/AccountPlus.svelte'
  import { px } from '$/lib'
</script>

<BaseLayout let:theme>
  <button
    on:click
    class="w-full h-full flex flex-col justify-center items-center text-sm text-center select-none">
    <div class="-ml-0.5em">
      <Icon size={px(4)} color="var(--{colors[theme]})" />
    </div>
    Asociază-te
  </button>
</BaseLayout>
