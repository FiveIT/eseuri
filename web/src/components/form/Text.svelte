<script lang="ts">
  import Base from './internal/Base.svelte'
  import { text, placeholderText, color } from '$/lib'

  export let name: string
  export let placeholder = ''
  export let required = false

  export let value = ''
</script>

<Base let:theme>
  <label for={name} class="place-self-center select-none text-center {text[theme]}"><slot /></label>
  <input
    id={name}
    {name}
    {placeholder}
    {required}
    bind:value
    type="text"
    class="col-span-2 {text[theme]} placeholder-{placeholderText[theme].slice(
      5
    )} text-sm bg-transparent"
    style="--color: var(--{color[theme]})" />
</Base>

<style>
  input:-webkit-autofill,
  input:-webkit-autofill:hover,
  input:-webkit-autofill:focus,
  input:-webkit-autofill:active {
    transition: background-color 5000s ease-in-out 0s;
  }

  input {
    color: var(--color) !important;
    -webkit-text-fill-color: var(--color) !important;
  }
</style>
