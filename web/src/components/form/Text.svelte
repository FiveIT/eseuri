<script lang="ts">
  import Base from './internal/Base.svelte'

  export let name: string
  export let placeholder = ''
  export let suggestions: string[] = []

  export let value = ''

  $: list = suggestions.length > 0 ? `${name}_suggestions` : undefined
</script>

<Base>
  <label for={name} class="place-self-center select-none"><slot /></label>
  <input
    {list}
    id={name}
    {name}
    {placeholder}
    bind:value
    type="text"
    class="col-span-2 placeholder-gray text-sm bg-transparent" />
  {#if suggestions.length}
    <datalist id={list}>
      {#each suggestions as v}
        <option value={v} />
      {/each}
    </datalist>
  {/if}
</Base>
