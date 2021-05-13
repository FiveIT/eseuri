<script context="module" lang="ts">
  import { go, Form, LayoutContext } from '$/components'
  import type { SubmitArgs } from '$/components'
  import { fromMutation, status, RequestError, getHeaders } from '$/lib'
  import client from '$/graphql/client'
  import { UPDATE_WORK_STATUS } from '$/graphql/queries'
  import type { WorkStatus } from '$/graphql/queries'

  import type { GotoHelper } from '@roxi/routify'
  import type { Writable } from 'svelte/store'
  import { of } from 'rxjs'
  import { map, tap, switchMap, catchError } from 'rxjs/operators'
  import { fromFetch } from 'rxjs/fetch'

  function onSubmit(
    workID: number,
    alive: Writable<boolean>,
    { body, message }: SubmitArgs,
    goto: GotoHelper
  ) {
    const status = body.get('status')!.toString() as WorkStatus

    return fromMutation(client, UPDATE_WORK_STATUS, { status, workID }).pipe(
      switchMap(({ update_works_by_pk }) => {
        if (!update_works_by_pk) {
          throw new RequestError(
            'Lucrarea pe care dorești să o revizuiești nu există, de fapt.',
            'Știu, înfricoșător... Vezi altă lucrare!'
          )
        }

        const {
          user: { first_name: name, email },
        } = update_works_by_pk
        const body = new URLSearchParams({
          name,
          email,
          status,
          url: `${window.location.origin}/work/${workID}`,
        })

        return fromFetch(`${import.meta.env.VITE_FUNCTIONS_URL}/notify-user`, {
          ...getHeaders(),
          method: 'POST',
          body: body,
        }).pipe(
          map(r => {
            if (!r.ok) {
              console.error({ notifyUserResponseError: r })
            }
          }),
          catchError(err => of(console.error({ notifyUserRequestError: err })))
        )
      }),
      map(() => ({ status: 'success', message } as const)),
      tap(() => go('/', alive, goto))
    )
  }

</script>

<script lang="ts">
  import type { UnrevisedWork } from '..'
  import Base from './Base.svelte'
  import Input from './review/InputOptions.svelte'
  import { goto } from '@roxi/routify'

  export let work: UnrevisedWork

</script>

{#await work.data then { workID }}
  <LayoutContext let:alive>
    <Base {work} additionalHeadingText={work.user ? `de ${work.user}` : ''}>
      {#if work.status === 'inReview' && work.teacherID === $status?.id}
        <Form
          name="review"
          cols={2}
          rows={1}
          hasTitle={false}
          message="Lucrare revizuită cu succes!"
          onSubmit={args => onSubmit(workID, alive, args, $goto)}
          submitOnChange>
          <Input />
        </Form>
      {/if}
    </Base>
  </LayoutContext>
{/await}
