<script lang="ts">
  import Base from './internal/Base.svelte'
  import { placeholderText, text } from '$/lib'

  export let name: string
  export let placeholder = ''
  export let required = false
  // eslint-disable-next-line no-undef
  export let type: svelte.JSX.HTMLAttributes<HTMLInputElement>['type'] = 'text'
  // eslint-disable-next-line no-unused-vars
  export let check: (input: HTMLInputElement) => void = () => {}

  let self: HTMLInputElement

</script>

<Base let:theme>
  <label for={name} class="place-self-center select-none text-center {text[theme]}"><slot /></label>
  <input
    {type}
    {name}
    id={name}
    {placeholder}
    {required}
    bind:this={self}
    on:input={() => check(self)}
    class="col-span-2 {text[theme]} placeholder-{placeholderText[theme].slice(
      5
    )} text-sm bg-transparent" />
</Base>

<style>
  input:-webkit-autofill,
  input:-webkit-autofill:hover,
  input:-webkit-autofill:focus,
  input:-webkit-autofill:active {
    transition: background-color 5000s ease-in-out 0s;
  }

  input {
    color: var(--white) !important;
    -webkit-text-fill-color: var(--white) !important;
  }

</style>
