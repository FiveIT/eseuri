<script context="module" lang="ts">
  import type { Role } from '$/lib'
  import { fromQuery, fromMutation, internalErrorNotification } from '$/lib'
  import client from '$/graphql/client'
  import { notify } from '$/components'
  import type { SubmitArgs, Notification } from '$/components'
  import { ASSOCIATE_WITH_STUDENT, ASSOCIATE_WITH_TEACHER, USER_BY_EMAIL } from '$/graphql/queries'

  import { CombinedError } from '@urql/svelte'
  import { switchMap, tap, map } from 'rxjs/operators'
  import { closeModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  function check(input: HTMLInputElement, role: Role) {
    const { value: email } = input

    fromQuery(client, USER_BY_EMAIL, { email })
      .pipe(tap(console.log))
      .subscribe({
        next({ users: [user] }) {
          if (!user) {
            input.setCustomValidity('Nu există vreun utilizator cu acest email.')
          } else if (user[role]) {
            input.setCustomValidity('Nu te poți asocia cu utilizatori care au același rol cu tine.')
          }
        },
        error(err) {
          if (err instanceof CombinedError) {
            notify(internalErrorNotification)
          } else {
            notify(internalErrorNotification)
          }
        },
      })
  }

  function submit({ body, message, explanation }: SubmitArgs, role: Role) {
    return fromQuery(client, USER_BY_EMAIL, { email: body.get('email')!.toString() }).pipe(
      switchMap(({ users: [user] }) =>
        fromMutation(client, role === 'student' ? ASSOCIATE_WITH_TEACHER : ASSOCIATE_WITH_STUDENT, {
          id: user!.id,
        })
      ),
      map(
        (): Notification => ({
          status: 'success',
          message,
          explanation,
        })
      ),
      tap(closeModal)
    )
  }

</script>

<script lang="ts">
  import { Form, TextConstraint, ActionsModal, ModalBase } from '$/components'
  import { onMount } from 'svelte'

  export let role: Role

  let focus: () => void

  onMount(() => focus())

</script>

<ModalBase>
  <Form
    name="associate"
    bind:focus
    cols={1}
    rows={2}
    message="Asocierea a fost trimisă cu succes!"
    explanation="Urmează doar ca celălalt să răspundă la cerea ta, iar apoi puteți împărtășii noile beneficii."
    onSubmit={args => submit(args, role)}>
    <span slot="legend">Inițiază o asociere</span>
    <TextConstraint
      name="email"
      type="email"
      placeholder="Scrie-l aici..."
      check={input => check(input, role)}
      required>
      Email-ul utilizatorului
    </TextConstraint>
    <ActionsModal slot="actions">Trimite cererea</ActionsModal>
  </Form>
</ModalBase>
