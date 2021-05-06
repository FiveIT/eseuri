<script lang="ts" context="module">
  const notification = {
    status: 'success',
    message: 'Te-ai înregistrat cu succes!',
  } as const
</script>

<script lang="ts">
  import SlimNav from '$/components/SlimNav.svelte'
  import Layout from '$/components/Layout.svelte'
  import LayoutContext from '$/components/LayoutContext.svelte'
  import Form from '$/components/form/Form.svelte'
  import type { SubmitArgs } from '$/components/form/Form.svelte'
  import Text from '$/components/form/Text.svelte'
  import Radio from '$/components/form/Radio.svelte'
  import Actions from '$/components/form/Actions.svelte'
  import Allow from '$/components/Allow.svelte'

  import { goto, metatags } from '@roxi/routify'
  import { from, of } from 'rxjs'
  import { map, mergeMap, tap } from 'rxjs/operators'

  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as window } from '$/components/Window.svelte'

  import type { BlobPropsInput, Role } from '$/lib/types'
  import { roleTranslation } from '$/content'
  import { handleGraphQLResponse } from '$/lib/util'
  import type { Writable } from 'svelte/store'
  import { go } from '$/components/Link.svelte'

  import { REGISTER_USER, TEACHER_REQUEST } from '$/graphql/queries'
  import client from '$/graphql/client'

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

  metatags.title = 'Înregistrare'

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

    return from(client.mutation(REGISTER_USER, vars).toPromise()).pipe(
      map(handleGraphQLResponse()),
      mergeMap(() =>
        role === 'teacher'
          ? from(client.mutation(TEACHER_REQUEST).toPromise()).pipe(map(handleGraphQLResponse()))
          : of(undefined)
      ),
      map(() => notification),
      tap(() => go('/', alive, $goto))
    )
  }
</script>

<!-- TODO: Make the school and county fields work as intended -->
<Allow unregistered redirect="/" dontNotify>
  <Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} blurBackground>
    <LayoutContext let:alive>
      <SlimNav logoOnly />
      <Form name="register" onSubmit={args => onSubmit(alive, args)}>
        <span slot="legend">Completează-ți profilul</span>
        <Text name="last_name" placeholder="Scrie-ți aici numele de familie..." required>
          Numele tău
        </Text>
        <Text name="first_name" placeholder="Scrie-l aici..." required>Primul prenume</Text>
        <Text name="middle_name" placeholder="Scrie-l aici...">Al doilea prenume</Text>
        <Text name="county" placeholder="Scrie aici judetul scolii..." required>
          Județul școlii tale
        </Text>
        <Text name="school" placeholder="Scrie aici numele școlii..." required>Școala ta</Text>
        <Radio name="role" options={roles} displayModifier={translateRole}>Ocupația ta</Radio>
        <Actions slot="actions" submitValue="Sunt gata" />
      </Form>
    </LayoutContext>
  </Layout>
</Allow>
