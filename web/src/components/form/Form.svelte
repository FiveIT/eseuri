<script lang="ts">
  export let action: string
  export let name: string
  export let formElement: HTMLFormElement
</script>

<form
  {action}
  method="POST"
  {name}
  id={name}
  class="col-span-6 row-span-6 grid grid-rows-6 grid-cols-6 gap-y-sm mx-xs"
  bind:this={formElement}
  on:submit|preventDefault>
  <fieldset class="col-span-6 row-span-4">
    <div
      class="grid grid-cols-2 grid-rows-4 gap-x-md gap-y-sm w-full h-full grid-flow-col font-sans antialiased">
      <legend class="col-span-2 text-md self-center">
        <slot name="legend" />
      </legend>
      <slot />
    </div>
  </fieldset>
  <slot name="actions" />
</form>
