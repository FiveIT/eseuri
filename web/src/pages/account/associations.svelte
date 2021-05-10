<script lang="ts">
  import { Spinner, LayoutContext } from '$/components'
  import { status, placeholderText } from '$/lib'
  import Associations from './_/Associations.svelte'

  import { metatags } from '@roxi/routify'

  metatags.title = 'Asocieri - Contul meu - Eseuri'
</script>

<LayoutContext let:theme>
  <div class="col-span-full grid grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm">
    {#await status()}
      <div class="col-start-1 h-full flex items-center justify-center">
        <Spinner />
      </div>
    {:then { role, id: userID }}
      <Associations {role} {userID} />
    {:catch}
      <p
        class="text-md font-sans antialiased {placeholderText[
          theme
        ]} col-start-1 h-full text-center flex items-center justify-center">
        Nu s-au putut obține asocierile, revino mai târziu.
      </p>
    {/await}
  </div>
</LayoutContext>
