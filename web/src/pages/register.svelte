<script lang="ts" context="module">
  const notification = {
    status: 'success',
    message: 'Te-ai înregistrat cu succes!',
  } as const

</script>

<script lang="ts">
  import {
    NavSlim,
    Layout,
    LayoutContext,
    Form,
    Text,
    Select,
    Spinner,
    Radio,
    Actions,
    Allow,
    orange,
    red,
    window,
    go,
  } from '$/components'
  import type { SubmitArgs } from '$/components'

  import type { BlobPropsInput, Role } from '$/lib'
  import { fromMutation, roleTranslation } from '$/lib'

  import { COUNTIES, REGISTER_USER, SCHOOLS, TEACHER_REQUEST } from '$/graphql/queries'
  import client from '$/graphql/client'

  import { redirect, metatags } from '@roxi/routify'
  import { query, operationStore } from '@urql/svelte'
  import type { Writable } from 'svelte/store'

  import { of } from 'rxjs'
  import { map, switchMap, tap } from 'rxjs/operators'

  metatags.title = 'Înregistrare - Eseuri'

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    x: 0,
    y: $window.height - orange.height,
    scale: 1.8,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    x: $window.width - red.width * 1,
    y: 0,
    scale: 2,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: $window.width * 0.65,
    y: $window.height * 0.9,
    scale: 1.5,
  }

  const roles: Role[] = ['student', 'teacher']
  const translateRole = (r: Role) => roleTranslation.ro[r].inarticulate.singular

  function onSubmit(alive: Writable<boolean>, { body: form }: SubmitArgs) {
    const role = form.get('role')!.toString()
    const vars = {
      firstName: form.get('first_name')!.toString(),
      middleName: form.get('middle_name')!.toString() || null,
      lastName: form.get('last_name')!.toString(),
      schoolID: parseInt(form.get('school')!.toString() || ''),
    } as const

    return fromMutation(client, REGISTER_USER, vars).pipe(
      switchMap(() => (role === 'teacher' ? fromMutation(client, TEACHER_REQUEST) : of(undefined))),
      map(() => notification),
      tap(() => go('/', alive, $redirect))
    )
  }

  let countyID: string | undefined
  const counties = query(operationStore(COUNTIES))

  const schools = query(operationStore(SCHOOLS, { countyID }))
  $: $schools.variables = { countyID }

</script>

<Allow unregistered redirect="/" dontNotify>
  <Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} blurBackground>
    <LayoutContext let:alive>
      <NavSlim logoOnly />
      {#if $counties.fetching || !$counties.data}
        <div class="flex items-center justify-center row-span-2 col-span-2 row-start-4 col-start-3">
          <Spinner message="O secundă..." />
        </div>
      {:else if $counties.error || $schools.error}
        <p
          class="text-md text-gray font-sans antialiased row-start-4 col-start-2 col-span-4 text-center">
          A apărut o eroare, revino mai târziu să te înregistrezi
        </p>
      {:else}
        <Form
          name="register"
          onSubmit={args => onSubmit(alive, args)}
          disabled={$schools.fetching || !$schools.data || $schools.error}>
          <span slot="legend">Completează-ți profilul</span>
          <Text name="last_name" placeholder="Scrie-ți aici numele de familie..." required>
            Numele tău
          </Text>
          <Text name="first_name" placeholder="Scrie-l aici..." required>Primul prenume</Text>
          <Text name="middle_name" placeholder="Scrie-l aici...">Al doilea prenume</Text>
          <Select
            name="county"
            placeholder="Scrie aici judetul scolii..."
            options={$counties.data.counties}
            mapper={county => county.id}
            display={county => county.name}
            bind:value={countyID}
            required>
            Județul școlii tale
          </Select>
          {#if $schools.fetching}
            <Spinner />
          {:else if $schools.data}
            <Select
              name="school"
              placeholder="Scrie aici numele școlii..."
              options={$schools.data.schools}
              mapper={school => school.id}
              display={school => school.name}
              required>Școala ta</Select>
          {/if}
          <Radio name="role" options={roles} displayModifier={translateRole}>Ocupația ta</Radio>
          <Actions slot="actions">Sunt gata</Actions>
        </Form>
      {/if}
    </LayoutContext>
  </Layout>
</Allow>
