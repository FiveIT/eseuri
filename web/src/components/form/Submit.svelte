<script lang="ts" context="module">
  import type { SubmitStatus } from './Form.svelte'

  import Spinner from '$/components/Spinner.svelte'
  import { px, border as b } from '$/lib'
  import type { Theme } from '$/lib'

  import IconSuccess from 'svelte-material-icons/Check.svelte'
  import IconError from 'svelte-material-icons/Exclamation.svelte'

  const emSize = 3

  const props = {
    size: px(emSize),
    color: 'white',
  }

  const statusIcons: Record<
    Exclude<SubmitStatus, 'awaitingInput'>,
    { icon: any; props?: Record<string, any> }
  > = {
    awaitingResponse: {
      icon: Spinner,
      props: {
        size: `${emSize}em`,
        longDuration: null,
      },
    },
    success: {
      icon: IconSuccess,
      props,
    },
    error: {
      icon: IconError,
      props,
    },
  }

  const bg: Record<Theme, string> = {
    default: 'bg-blue',
    white: 'bg-transparent',
  }

  const border: Record<Theme, string> = {
    default: '',
    white: `${b.color.white} ${b.all.white}`,
  }

</script>

<script lang="ts">
  import { getForm } from './Form.svelte'
  import { LayoutContext } from '$/components'

  const { formenctype, submitStatus } = getForm()

  export let value = ''
  export let big = false

</script>

<LayoutContext let:theme>
  <button
    type="submit"
    {formenctype}
    {value}
    class="col-span-1 h-full rounded text-white text-sm leading-none {bg[theme]} {border[
      theme
    ]} cursor-pointer flex justify-center items-center flex-1 {big
      ? 'w-submit px-sm'
      : 'max-w-col'}">
    {#if $submitStatus === 'awaitingInput'}
      <slot />
    {:else}
      <svelte:component
        this={statusIcons[$submitStatus].icon}
        {...statusIcons[$submitStatus].props} />
    {/if}
  </button>
</LayoutContext>
