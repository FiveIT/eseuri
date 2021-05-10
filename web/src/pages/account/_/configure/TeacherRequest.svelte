<script context="module" lang="ts">
  import { formatDate, border, internalErrorNotification, fromMutation } from '$/lib'
  import client from '$/graphql/client'
  import {
    TEACHER_REQUEST,
    REMOVE_TEACHER_REQUEST,
    TEACHER_REQUEST_TRACKING,
  } from '$/graphql/queries'
  import { notify, LayoutContext } from '$/components'

  import type { DocumentNode } from 'graphql'
  import type { TypedDocumentNode } from '@urql/svelte'

  type Status = '' | 'pending' | 'approved' | 'rejected'
  type Data<T> = Record<Status, T>

  // eslint-disable-next-line no-unused-vars
  const labels: Data<(time?: string) => string> = {
    '': () => 'Devino profesor',
    pending: time =>
      `Cererea ta de a deveni profesor făcută ${formatDate(time!, true)
        .reverse()
        .join(' ')} este în revizuire`,
    approved: () => 'Ești profesor',
    rejected: time =>
      `Cererea ta de a deveni profesor făcută ${formatDate(time!, true)
        .reverse()
        .join(' ')} a fost refuzată. Click pentru a continua.`,
  }

  const borders: Data<string> = {
    '': border.color.white,
    pending: `border-orange`,
    approved: `border-green-light`,
    rejected: `border-red`,
  }

  const bgs: Data<string> = {
    '': '',
    pending: '',
    approved: 'bg-green-light',
    rejected: 'bg-red',
  }

  function handler<Data, Variables extends object = {}>(
    query: DocumentNode | TypedDocumentNode<Data, Variables> | string,
    message?: string,
    explanation?: string
  ) {
    return () =>
      fromMutation(client, query).subscribe({
        next() {
          notify({
            status: 'success',
            message: message || 'Operația a fost executată cu succes!',
            explanation,
          })
        },
        error() {
          notify(internalErrorNotification)
        },
      })
  }

  const handlers: Partial<Data<() => void>> = {
    '': handler(
      TEACHER_REQUEST,
      'Cererea ta a fost trimisă cu succes!',
      'Ea va fi revizuită de un administrator în scurt timp, fiind foarte probabil să fiți contactați pe email-ul dumneavoastră cu scopul verificării eligibilității pentru această poziție.'
    ),
    rejected: handler(REMOVE_TEACHER_REQUEST),
  }
</script>

<script lang="ts">
  import { subscription, operationStore } from '@urql/svelte'

  const tr = subscription(operationStore(TEACHER_REQUEST_TRACKING))
  $: if ($tr.error) {
    notify({
      ...internalErrorNotification,
      message: `Nu s-a putut obține stadiul cererii tale de profesor, dacă există.`,
    })
  }

  $: request = $tr.data?.teacher_requests[0]
  $: status = request?.status || ('' as const)
</script>

<LayoutContext let:theme>
  <button
    disabled={!handlers[status]}
    on:click={() => handlers[status]?.()}
    class="rounded {border.all[
      theme
    ]} disabled:cursor-default font-sans text-sm antialiased transition-all duration-100 ease-out {borders[
      status
    ]} {bgs[status]}">
    {labels[status](request?.created_at)}
  </button>
</LayoutContext>
