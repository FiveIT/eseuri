<script lang="ts" context="module">
  import { notify } from '$/components/Notifications.svelte'
  import type { Notification } from '$/components/Notifications.svelte'
  import { RequestError, internalErrorNotification, getHeaders } from '$/lib/user'
  import type { Nullable } from '$/lib/types'
  import { isNonNullable } from '$/lib/types'

  import { from, of, throwError } from 'rxjs'
  import { fromFetch } from 'rxjs/fetch'
  import type { ObservableInput } from 'rxjs'
  import { filter, mergeMap, tap } from 'rxjs/operators'
  import { CombinedError } from '@urql/svelte'
  import { getContext, setContext } from 'svelte'
  import { writable } from 'svelte/store'
  import type { Readable, Writable } from 'svelte/store'

  const contextKey = {}

  type SubmitStatus = 'awaitingInput' | 'awaitingResponse' | 'error' | 'success'

  interface Context {
    submitStatus: Readable<SubmitStatus>
    formenctype: string
  }

  export function getForm(): Context {
    return getContext(contextKey)
  }

  function createStatusStore(): Writable<SubmitStatus> {
    return writable('awaitingInput')
  }

  function setForm(ctx: Context) {
    setContext(contextKey, ctx)
  }

  function error(err: any): void {
    if (err instanceof RequestError) {
      notify({
        status: 'error',
        message: err.message,
        explanation: err.explanation,
      })
    } else if (err instanceof CombinedError) {
      return error(new RequestError(err))
    } else {
      console.error({ formError: err })
      notify(internalErrorNotification)
    }
  }

  interface SubmitArgs {
    body: FormData
    action: string
    method: string
    message: string
    explanation?: string
  }

  // eslint-disable-next-line no-unused-vars
  type SubmitFn = (args: SubmitArgs) => ObservableInput<Nullable<Notification>>

  const submit = (
    onSubmit: SubmitFn,
    submitArgs: Omit<SubmitArgs, 'body'>,
    submitStatus: Writable<SubmitStatus>
  ) => ({ target }: Event) => {
    submitStatus.set('awaitingResponse')
    let handle: ReturnType<typeof setTimeout> | undefined

    return from(
      onSubmit({
        body: new FormData(target as HTMLFormElement),
        ...submitArgs,
      })
    )
      .pipe(filter(isNonNullable))
      .subscribe({
        next(notification) {
          submitStatus.set('success')
          notify(notification)
        },
        error(err) {
          submitStatus.set('error')
          handle && clearTimeout(handle)
          handle = setTimeout(() => submitStatus.set('awaitingInput'), 5000)
          error(err)
        },
      })
  }

  const messages: Record<number, string> = {
    400: 'Formularul trimis sau datele de autentificare sunt invalide.',
    401: 'Nu ești autorizat pentru a încărca o lucrare.',
    500: 'A apărut o eroare internă, încearcă mai târziu.',
  }

  export const defaultSubmitFn: SubmitFn = ({ body, action, method, message, explanation }) =>
    fromFetch(action, {
      body,
      method,
      cache: 'no-cache',
      ...getHeaders(),
      selector: r => r.json().then(v => [v, r.ok, r.status] as const),
    }).pipe(
      mergeMap(([{ error }, ok, status]) =>
        ok
          ? of({ status: 'success', message, explanation } as const)
          : throwError(() => new RequestError(messages[status], error))
      )
    )

  export type { SubmitArgs, SubmitFn, Context, SubmitStatus }
</script>

<script lang="ts">
  export let action: string = ''
  export let name: string
  export let formenctype: 'application/x-www-form-urlencoded' | 'multipart/form-data' =
    'application/x-www-form-urlencoded'
  export let message = 'Formularul a fost trimis cu succes!'
  export let explanation: string | undefined = undefined
  export let onSubmit: SubmitFn = defaultSubmitFn

  const submitStatus = createStatusStore()

  setForm({ submitStatus, formenctype })

  const submitFn = submit(onSubmit, { action, method: 'POST', message, explanation }, submitStatus)
</script>

<form
  {action}
  method="POST"
  {name}
  id={name}
  {formenctype}
  class="col-span-6 row-span-6 grid grid-rows-6 grid-cols-6 gap-y-sm mx-xs"
  on:submit|preventDefault={submitFn}>
  <fieldset class="col-span-6 row-span-4">
    <div
      class="grid grid-cols-2 grid-rows-4 gap-x-md gap-y-sm w-full h-full grid-flow-col font-sans antialiased">
      <legend class="col-span-2 text-md self-center">
        <slot name="legend" />
      </legend>
      <slot />
    </div>
  </fieldset>
  <slot name="actions" />
</form>
