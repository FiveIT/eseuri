<script context="module" lang="ts">
  import { go, Form, LayoutContext, Link } from '$/components'
  import type { SubmitArgs } from '$/components'
  import { fromMutation, status } from '$/lib'
  import type { UserStatus } from '$/lib'
  import client from '$/graphql/client'
  import { UPDATE_WORK_STATUS } from '$/graphql/queries'
  import type { WorkStatus } from '$/graphql/queries'

  import type { GotoHelper } from '@roxi/routify'
  import type { Writable } from 'svelte/store'
  import { map, tap } from 'rxjs/operators'

  function onSubmit(
    workID: number,
    alive: Writable<boolean>,
    { body, message }: SubmitArgs,
    goto: GotoHelper
  ) {
    return fromMutation(client, UPDATE_WORK_STATUS, {
      status: body.get('status')!.toString() as WorkStatus,
      workID,
    }).pipe(
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

  let user: UserStatus | undefined

  status().then(s => (user = s))

  export let work: UnrevisedWork
</script>

<!-- TODO: Don't use this for previewing bookmarks, as student's can't access information about other students required by this reader. -->
{#await work.data then { workID }}
  <LayoutContext let:alive>
    <Base {work} additionalHeadingText="de {work.user}">
      {#if work.status === 'inReview' && work.teacherID === user?.id}
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
