<script context="module" lang="ts">
</script>

<script lang="ts">
  import { Row, Cell, Spinner, Error } from './table'

  import { DeleteButton } from '$/components'
  import { BOOKMARKS } from '$/graphql/queries'
  import { formatDate, internalErrorNotification } from '$/lib'

  import { query, operationStore } from '@urql/svelte'

  const content = query(operationStore(BOOKMARKS))

  import { removeBookmark } from '../../work/_/bookmark'
  import { notify } from '$/components'

  let lastPolicy: string = 'cache-and-network'

  async function handler(workID: number) {
    try {
      await removeBookmark(workID)

      if (lastPolicy === 'cache-and-network') {
        $content.context = { requestPolicy: 'network-only' }
        lastPolicy = 'network-only'
      } else {
        $content.context = { requestPolicy: 'cache-and-network' }
        lastPolicy = 'cache-and-network'
      }

      notify({
        status: 'success',
        message: 'Marcajul a fost șters!',
      })
    } catch {
      notify(internalErrorNotification)
    }
  }
</script>

{#if $content.data}
  {#each $content.data.bookmarks as { name, created_at, work } (work.id)}
    <div class="relative group col-span-full h-full">
      <Row bordered href="/work/{work.id}" id={work.id.toString()}>
        <Cell>{work.essay ? 'Eseu' : 'Caracterizare'}</Cell>
        <Cell cols={2}>{name}</Cell>
        <Cell cols={2}
          >{work.essay ? work.essay.title.name : work.characterization.character.name}</Cell>
        <Cell>{formatDate(created_at, true)[0]}</Cell>
      </Row>
      <div class="absolute -top-1em -left-1em">
        <DeleteButton on:click={() => handler(work.id)} />
      </div>
    </div>
  {/each}
{:else if $content.error}
  <Error>Nu s-au putut obține marcajele, revino mai târziu.</Error>
{:else}
  <Spinner />
{/if}
