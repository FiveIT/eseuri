<script lang="ts">
  import Base from './internal/Base.svelte'

  export let name: string
  export let placeholder = ''
  export let required = false

  export let value = ''
</script>

<Base>
  <label for={name} class="place-self-center select-none text-center"><slot /></label>
  <input
    id={name}
    {name}
    {placeholder}
    {required}
    bind:value
    type="text"
    class="col-span-2 placeholder-gray text-sm bg-transparent" />
</Base>

<style>
  input:-webkit-autofill,
  input:-webkit-autofill:hover,
  input:-webkit-autofill:focus,
  input:-webkit-autofill:active {
    transition: background-color 5000s ease-in-out 0s;
  }
</style>
