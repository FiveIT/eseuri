<script lang="ts">
  import { Form, Text, Select, Spinner as SpinnerOG, Submit } from '$/components'
  import Base from '$/components/form/internal/ActionsLayout.svelte'
  import { COUNTIES, REGISTER_USER, SCHOOLS } from '$/graphql/queries'
  import type { Self } from '$/graphql/queries'
  import { operationStore, query } from '@urql/svelte'
  import Spinner from './Spinner.svelte'
  import Error from './Error.svelte'
  import { fromMutation } from '$/lib'
  import client from '$/graphql/client'
  import { map } from 'rxjs/operators'

  export let user: Self

  let firstName = user.first_name
  let middleName = user.middle_name || undefined
  let lastName = user.last_name
  let countyID = user.school.county.id
  let schoolID = user.school.id

  const counties = query(operationStore(COUNTIES, undefined, { requestPolicy: 'cache-first' }))
  const schools = query(operationStore(SCHOOLS, { countyID }))
  $: $schools.variables = { countyID }

  function onSubmit() {
    return fromMutation(client, REGISTER_USER, {
      firstName,
      middleName: middleName || null,
      lastName,
      schoolID,
    }).pipe(
      map(
        () =>
          ({
            status: 'success',
            message: 'Datele tale au fost actualizate cu succes!',
          } as const)
      )
    )
  }

</script>

{#if $counties.fetching || !$counties.data}
  <Spinner />
{:else if $counties.error || $schools.error}
  <Error>A apărut o eroare, revino mai târziu</Error>
{:else}
  <div class="col-span-3 row-span-6 grid grid-cols-3 gap-x-md gap-y-sm grid-rows-6">
    <Form cols={1} rows={6} hasTitle={false} name="update" {onSubmit}>
      <Text name="last_name" placeholder="Scrie-l aici..." bind:value={lastName} required
        >Numele tău</Text>
      <Text name="first_name" placeholder="Scrie-l aici..." bind:value={firstName} required
        >Primul prenume</Text>
      <Text name="middle_name" placeholder="Scrie-l aici..." bind:value={middleName}
        >Al doilea prenume</Text>
      <Select
        name="county"
        placeholder="Alege o opțiune..."
        bind:value={countyID}
        mapper={c => c.id}
        display={c => c.name}
        options={$counties.data.counties}>Județul școlii tale</Select>
      {#if $schools.fetching || !$schools.data}
        <SpinnerOG longDuration={null} />
      {:else}
        <Select
          name="school"
          placeholder="Alege o opțiune..."
          bind:value={schoolID}
          mapper={s => s.id}
          display={s => s.name}
          options={$schools.data.schools}>Școala ta</Select>
      {/if}
      <Base slot="actions">
        <Submit big>Actualizează-ți contul</Submit>
      </Base>
    </Form>
  </div>
{/if}
