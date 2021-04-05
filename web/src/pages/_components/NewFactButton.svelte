<script>
  import Text from '$/components/text/Inline.svelte'

  export let disabled = false
</script>

<button
  on:click
  {disabled}
  class="blur p-lg border rounded transition bg-white bg-opacity-50 cursor-pointer select-none hover:(border-orange bg-orange text-white) focus-visible:(border-orange bg-orange text-white) focus:outline-transparent">
  <Text>
    <slot />
  </Text>
</button>
