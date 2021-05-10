<script lang="ts">
  import Base from './internal/Base.svelte'
  import { placeholderText, text } from '$/lib'

  export let options: readonly any[]
  export let mapper = (option: any) => option
  export let display = (value: any) => value

  export let name: string
  export let placeholder = ''
  export let required = false

  export let value: any = undefined

</script>

<Base let:theme>
  <label for={name} class="place-self-center text-center select-none {text[theme]}">
    <slot />
  </label>
  <select
    {name}
    id={name}
    {placeholder}
    {required}
    bind:value
    class="col-span-2 font-sans text-sm placeholder-{placeholderText[theme].slice(5)} {text[
      theme
    ]} bg-transparent">
    {#each options as opt}
      <option value={mapper(opt)}>{display(opt)}</option>
    {/each}
  </select>
</Base>
