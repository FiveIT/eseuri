<script lang="ts">
  import { BaseLayout } from './internal'
  import Button from './association/IncomingResponseButton.svelte'
  import type { FullNamer } from '$/lib'
  import { getName } from '$/lib'

  export let user: FullNamer
</script>

<BaseLayout darkBg>
  <div class="h-full grid grid-cols-2 grid-rows-2 gap-x-md gap-y-sm">
    <div
      class="col-span-full place-self-center text-center font-sans text-sm antialiased leading-tight">
      Asociere cu:<br />
      <span class="text-1.25rem">{getName(user)}</span>
    </div>
    <Button response={true} on:response>Da</Button>
    <Button response={false} on:response>Nu</Button>
  </div>
</BaseLayout>
