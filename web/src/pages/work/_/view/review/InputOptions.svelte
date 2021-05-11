<script context="module" lang="ts">
  import type { WorkStatus } from '$/graphql/queries'
  import IconApprove from 'svelte-material-icons/ThumbUp.svelte'
  import IconReject from 'svelte-material-icons/ThumbDown.svelte'

  type Value = Exclude<WorkStatus, 'draft' | 'pending' | 'inReview'>

  const values: Value[] = ['approved', 'rejected']

  const data: Record<
    Value,
    { icon: any; label: string; textOffset?: string; iconOffset?: string }
  > = {
    approved: {
      label: 'Aprobă',
      icon: IconApprove,
      textOffset: '0.33em',
    },
    rejected: {
      label: 'Respinge',
      icon: IconReject,
      iconOffset: '0.3em',
    },
  }

  const name = 'status'
</script>

<script lang="ts">
  import ActionsLayout from '$/components/form/internal/ActionsLayout.svelte'

  let group: Value
</script>

<ActionsLayout>
  {#each values as value}
    <input
      type="radio"
      {name}
      id="{name}_{value}"
      bind:group
      checked={group === value}
      class="absolute opacity-0 w-0 h-0"
      {value}
      required />
    <label
      for="{name}_{value}"
      class="w-full h-full flex items-center space-x-0.3em font-sans text-sm antialiased text-black cursor-pointer focus-visible:outline-solid-black">
      <div class="w-1.4em h-1.4em {data[value].iconOffset ? `mt-${data[value].iconOffset}` : ''}">
        <svelte:component this={data[value].icon} size="100%" color="var(--black)" />
      </div>
      <span class={data[value].textOffset ? `mt-${data[value].textOffset}` : ''}
        >{data[value].label}</span>
    </label>
  {/each}
</ActionsLayout>

<style>
  input:focus + label {
    outline: auto;
  }
</style>
