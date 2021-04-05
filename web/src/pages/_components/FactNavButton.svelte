<script>
  import Text from '$/components/text/Inline.svelte'
  export let disabled = false
</script>

<button
  {disabled}
  on:click
  class="blur p-sm border rounded transition bg-white bg-opacity-50 cursor-pointer select-none hover:(bg-blue border-blue text-white) focus-visible:(bg-blue border-blue text-white) disabled:(pointer-events-none opacity-50) focus:outline-transparent">
  <Text>
    <slot />
  </Text>
</button>
