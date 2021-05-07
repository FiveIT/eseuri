<script lang="ts" context="module">
  import { notify } from '$/components'
  import {
    isNonNullable,
    requestError,
    RequestError,
    internalErrorNotification,
    getHeaders,
  } from '$/lib'
  import type { Notification, Nullable, MessagesRecord } from '$/lib'

  import { from, of } from 'rxjs'
  import { fromFetch } from 'rxjs/fetch'
  import type { ObservableInput } from 'rxjs'
  import { filter, switchMap } from 'rxjs/operators'
  import { getContext, setContext } from 'svelte'
  import { writable } from 'svelte/store'
  import type { Readable, Writable } from 'svelte/store'

  const contextKey = {}

  type SubmitStatus = 'awaitingInput' | 'awaitingResponse' | 'error' | 'success'

  interface Context {
    submitStatus: Readable<SubmitStatus>
    formenctype: string
    rows: number
    cols: number
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

  const messages: MessagesRecord = {
    400: 'Formularul trimis sau datele de autentificare sunt invalide.',
    401: 'Nu ești autorizat pentru a încărca o lucrare.',
  }

  export const defaultSubmitFn: SubmitFn = ({ body, action, method, message, explanation }) =>
    fromFetch(action, {
      body,
      method,
      cache: 'no-cache',
      ...getHeaders(),
      selector: r => r.json().then(v => [v, r.ok, r.status] as const),
    }).pipe(
      switchMap(([{ error }, ok, status]) => {
        if (ok) {
          return of({ status: 'success', message, explanation } as const)
        }

        throw requestError(messages, status, error)
      })
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
  export let rows = 4
  export let cols = 2

  let form: HTMLFormElement

  export const focus = () => form.querySelector('input')?.focus()

  const submitStatus = createStatusStore()

  setForm({ submitStatus, formenctype, rows, cols })

  const submitFn = submit(onSubmit, { action, method: 'POST', message, explanation }, submitStatus)
</script>

<form
  {action}
  method="POST"
  {name}
  id={name}
  {formenctype}
  bind:this={form}
  class="col-span-{3 * cols} row-span-{rows + 2} grid grid-rows-{rows + 2} grid-cols-{3 *
    cols} gap-y-sm"
  on:submit|preventDefault={submitFn}>
  <fieldset class="col-span-{3 * cols} row-span-{rows}">
    <div
      class="grid grid-cols-{cols} grid-rows-{rows} gap-x-md gap-y-sm w-full h-full grid-flow-col font-sans antialiased">
      <legend class="col-span-{cols} text-md self-center">
        <slot name="legend" />
      </legend>
      <slot />
    </div>
  </fieldset>
  <slot name="actions" />
</form>
