<script lang="ts">
  import Base from './internal/Base.svelte'
  import { text } from '$/lib'

  export let name: string
  export let options: readonly any[] = []
  // eslint-disable-next-line no-unused-vars
  export let displayModifier = (option: any, index: number) => option

  export let selected = options.length > 0 ? options[0] : undefined

</script>

<Base let:theme>
  <span class="place-self-center select-none {text[theme]} leading-none"><slot /></span>
  {#each options as value, i}
    <input
      id={`${name}_${value}`}
      bind:group={selected}
      type="radio"
      {name}
      {value}
      checked={selected === value}
      class="absolute opacity-0 w-0 h-0" />
    <label
      for={`${name}_${value}`}
      class="cursor-pointer capitalize place-self-center select-none {text[theme]}">
      {displayModifier(value, i)}
    </label>
  {/each}
</Base>

<style>
  input:focus-visible + label {
    outline: auto;
  }

  input:checked + label {
    text-decoration: underline;
  }

</style>
