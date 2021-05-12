<script context="module" lang="ts">
  import type { WorkStatus } from '$/graphql/queries'

  const statuses: WorkStatus[] = ['draft', 'pending', 'inReview', 'approved', 'rejected']

  export const statusTranslations = {
    draft: 'În lucru',
    pending: 'În așteptare',
    inReview: 'În revizuire acum',
    approved: 'Aprobate',
    rejected: 'Respinse',
  }

  function isWorkStatus(v: any): v is WorkStatus {
    return statuses.includes(v)
  }

</script>

<script lang="ts">
  import { LayoutContext } from '$/components'
  import { filterShadow, text, status as userStatus, statusError } from '$/lib'
  import { Table, Row, Header, Spinner, Error } from './_/table'
  import Works from './_/Works.svelte'

  import { params, goto, metatags } from '@roxi/routify'

  metatags.title = 'Lucrări - Contul meu - Eseuri'

  let status: WorkStatus = isWorkStatus($params.status) ? $params.status : 'pending'

  $: $goto('/account/works', { status })

</script>

<LayoutContext let:theme>
  <!-- don't add draft status as no works can be drafts at the moment -->
  <div class="row-start-2 row-span-4 grid auto-rows-layout gap-y-sm sticky top-9rem">
    {#each statuses.slice(1) as value}
      <div class="relative h-full {filterShadow[theme]}">
        <input
          type="radio"
          id="status_{value}"
          name="status"
          {value}
          bind:group={status}
          class="absolute opacity-0 w-0 h-0"
          required />
        <label
          for="status_{value}"
          class="h-full font-sans text-sm antialiased flex items-center justify-center text-center cursor-pointer select-none {text[
            theme
          ]}">{statusTranslations[value]}</label>
      </div>
    {/each}
  </div>
  <Table start={2} cols={5}>
    <Row>
      <Header>Tip</Header>
      <Header cols={2}>Subiect</Header>
      <Header>Ultima actualizare</Header>
      <Header>Profesor responsabil</Header>
    </Row>
    {#if $userStatus}
      <Works {status} userID={$userStatus.id} />
    {:else if $statusError}
      <Error />
    {:else}
      <Spinner />
    {/if}
  </Table>
</LayoutContext>

<style>
  input:checked + label {
    text-decoration: underline;
  }

  input:focus-visible + label {
    outline: auto;
  }

</style>
