<script context="module" lang="ts">
  import { go, Form, LayoutContext, defaultSubmitFn } from '$/components'
  import type { SubmitArgs } from '$/components'
  import { fromMutation, status } from '$/lib'
  import client from '$/graphql/client'
  import { UPDATE_WORK_STATUS } from '$/graphql/queries'
  import type { WorkStatus } from '$/graphql/queries'

  import type { GotoHelper } from '@roxi/routify'
  import type { Writable } from 'svelte/store'
  import { map, tap, switchMap } from 'rxjs/operators'

  function onSubmit(
    workID: number,
    alive: Writable<boolean>,
    { body, message }: SubmitArgs,
    goto: GotoHelper
  ) {
    const status = body.get('status')!.toString() as WorkStatus

    return fromMutation(client, UPDATE_WORK_STATUS, { status, workID }).pipe(
      switchMap(({ update_works_by_pk }) => {
        const body = new FormData()

        body.append('name', update_works_by_pk!.first_name)
        body.append('email', update_works_by_pk!.email)
        body.append('status', status)
        body.append('workID', workID.toString())
        body.append('url', window.location.origin)

        return defaultSubmitFn({
          action: `${import.meta.env.VITE_FUNCTIONS_URL}/notify-user`,
          body,
          timeout: 15000,
          method: 'POST',
          message: '',
        })
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
