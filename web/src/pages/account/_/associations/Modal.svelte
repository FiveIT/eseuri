<script context="module" lang="ts">
  import type { Role } from '$/lib'
  import { fromQuery, fromMutation } from '$/lib'
  import client from '$/graphql/client'
  import type { SubmitArgs } from '$/components'
  import { ASSOCIATE_WITH_STUDENT, ASSOCIATE_WITH_TEACHER, USER_BY_EMAIL } from '$/graphql/queries'

  import { of } from 'rxjs'
  import { switchMap, tap, map, catchError } from 'rxjs/operators'
  import { closeModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  class InputError extends Error {
    constructor(public readonly message: string) {
      super(message)
    }
  }

  const notification = {
    status: 'success',
    message: 'Asocierea a fost trimisă cu succes!',
    explanation: `Urmează doar ca celălalt să răspundă la cerea ta, iar apoi puteți împărtăși noile beneficii.`,
  } as const

  function submit({ body }: SubmitArgs, role: Role, userID: number, input: HTMLInputElement) {
    const email = body.get('email')!.toString()

    return fromQuery(client, USER_BY_EMAIL, { email }, { requestPolicy: 'network-only' }).pipe(
      switchMap(({ users: [user] }) => {
        if (!user) {
          throw new InputError('Nu există un utilizator cu această adresă de email.')
        }

        if (user.id === userID) {
          throw new InputError('Nu te poți asocia cu tine însuți')
        }

        if (user[role] !== null) {
          throw new InputError('Nu te poți asocia cu persoane cu același rol.')
        }

        return fromMutation(
          client,
          role === 'student' ? ASSOCIATE_WITH_TEACHER : ASSOCIATE_WITH_STUDENT,
          { id: user.id }
        )
      }),
      map(() => notification),
      tap(closeModal),
      catchError(err => {
        if (err instanceof InputError) {
          input.setCustomValidity(err.message)

          return of(undefined)
        }

        throw err
      })
    )
  }

</script>

<script lang="ts">
  import { Form, TextConstraint, ActionsModal, ModalGrid } from '$/components'
  import { onMount } from 'svelte'

  export let role: Role
  export let userID: number

  let focus: () => void
  let input: HTMLInputElement

  onMount(() => focus())

</script>

<ModalGrid>
  <Form
    name="associate"
    bind:focus
    cols={1}
    rows={2}
    onSubmit={args => submit(args, role, userID, input)}>
    <span slot="legend">Inițiază o asociere</span>
    <TextConstraint
      name="email"
      type="email"
      placeholder="Scrie-l aici..."
      bind:self={input}
      required>
      Email-ul utilizatorului
    </TextConstraint>
    <ActionsModal slot="actions">Trimite cererea</ActionsModal>
  </Form>
</ModalGrid>
