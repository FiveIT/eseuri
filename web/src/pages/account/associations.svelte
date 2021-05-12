<script lang="ts">
  import { Spinner, LayoutContext } from '$/components'
  import { status, statusError, placeholderText, filterShadow } from '$/lib'
  import Associations from './_/Associations.svelte'

  import { metatags } from '@roxi/routify'

  metatags.title = 'Asocieri - Contul meu - Eseuri'

</script>

<LayoutContext let:theme>
  <div class="col-span-full grid grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm">
    {#if $status}
      <Associations role={$status.role} userID={$status.id} />
    {:else if $statusError}
      <p
        class="text-md font-sans antialiased {placeholderText[theme]} {filterShadow[
          theme
        ]} col-start-2 h-full text-center flex items-center justify-center">
        Nu s-au putut obține asocierile, revino mai târziu.
      </p>
    {:else}
      <div class="col-start-2 h-full flex items-center justify-center">
        <Spinner />
      </div>
    {/if}
  </div>
</LayoutContext>
