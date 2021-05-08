<script lang="ts">
  import { Spinner, Works, notify } from '$/components'
  import { internalErrorNotification } from '$/lib'

  export let loading = false
  export let error = false
  export let works: any[] | undefined

  $: if (error) {
    notify(internalErrorNotification)
  }
</script>

<slot name="typeSelector" />
{#if loading}
  <div class="row-start-5 col-span-6 flex justify-center">
    <Spinner />
  </div>
{:else if !error}
  <Works {works} />
{/if}
