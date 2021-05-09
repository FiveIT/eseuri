<script lang="ts" context="module">
  import type { SubmitStatus } from './Form.svelte'

  import Spinner from '$/components/Spinner.svelte'
  import { px } from '$/lib'

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
</script>

<script lang="ts">
  import { getForm } from './Form.svelte'

  const { formenctype, submitStatus } = getForm()

  export let value = ''
</script>

<button
  type="submit"
  {formenctype}
  {value}
  class="col-span-1 h-full rounded text-white text-sm bg-blue cursor-pointer flex justify-center items-center flex-1 max-w-col">
  {#if $submitStatus == 'awaitingInput'}
    <slot />
  {:else}
    <svelte:component
      this={statusIcons[$submitStatus].icon}
      {...statusIcons[$submitStatus].props} />
  {/if}
</button>
