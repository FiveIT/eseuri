<script lang="ts">
  import Base from './internal/Base.svelte'
  import { text, placeholderInputText, color } from '$/lib'

  export let name: string
  export let placeholder = ''
  export let required = false

  export let value = ''

</script>

<Base let:theme>
  <label for={name} class="place-self-center select-none text-center {text[theme]} leading-none"
    ><slot /></label>
  <input
    id={name}
    {name}
    {placeholder}
    {required}
    bind:value
    type="text"
    class="col-span-2 {text[theme]} {placeholderInputText[theme]} text-sm bg-transparent"
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
    -webkit-text-fill-color: var(--color);
  }

</style>
