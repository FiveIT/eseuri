<script lang="ts">
  import { Row, Cell, Spinner, Error } from './table'

  import type { WorkStatus } from '$/graphql/queries'
  import { WORKS } from '$/graphql/queries'

  import { formatDate, getName } from '$/lib'

  import { subscription, operationStore } from '@urql/svelte'

  export let userID: number
  export let status: WorkStatus

  const sub = subscription(operationStore(WORKS, { userID, status }))
  $: $sub.variables = { userID, status }
</script>

{#if $sub.data}
  {#each $sub.data.works as work (work.id)}
    <Row bordered href="/work/{work.id}" id={work.id.toString()}>
      <Cell>{work.essay ? 'Eseu' : 'Caracterizare'}</Cell>
      <Cell cols={2}
        >{work.essay ? work.essay.title.name : work.characterization.character.name}</Cell>
      <Cell>{@html formatDate(work.updated_at || work.created_at, true, true)[0]}</Cell>
      <Cell>
        {work.teacher ? getName(work.teacher.user) : '–'}
      </Cell>
    </Row>
  {/each}
{:else if $sub.error}
  <Error>Nu s-au putut obține lucrările, revino mai târziu.</Error>
{:else}
  <Spinner />
{/if}
