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

  import { from, of, throwError } from 'rxjs'
  import { fromFetch } from 'rxjs/fetch'
  import type { ObservableInput } from 'rxjs'
  import { filter, switchMap, timeout as rxTimeout, first } from 'rxjs/operators'
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
    disabled: Readable<boolean>
    hasTitle: Readable<boolean>
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
      error(requestError(err))
    } else if (err instanceof TimeoutError) {
      notify({
        status: 'error',
        message: err.message,
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
    timeout: number
    explanation?: string
  }

  // eslint-disable-next-line no-unused-vars
  type SubmitFn = (args: SubmitArgs) => ObservableInput<Nullable<Notification>>

  class TimeoutError extends Error {
    constructor(public readonly message: string) {
      super(message)
    }
  }

  const submit =
    (
      onSubmit: SubmitFn,
      submitArgs: Omit<SubmitArgs, 'body'>,
      submitStatus: Writable<SubmitStatus>
    ) =>
    (form: HTMLFormElement) => {
      submitStatus.set('awaitingResponse')
      let handle: ReturnType<typeof setTimeout> | undefined

      const scheduleReset = () => {
        handle && clearTimeout(handle)
        handle = setTimeout(() => submitStatus.set('awaitingInput'), 5000)
      }

      return from(
        onSubmit({
          body: new FormData(form),
          ...submitArgs,
        })
      )
        .pipe(
          first(),
          rxTimeout({
            each: submitArgs.timeout,
            with: () =>
              throwError(() => new TimeoutError('Operația a luat prea mult, încearcă mai târziu!')),
          }),
          filter(isNonNullable)
        )
        .subscribe({
          next(notification) {
            submitStatus.set('success')
            scheduleReset()
            notify(notification)
          },
          error(err) {
            submitStatus.set('error')
            scheduleReset()
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
  import { CombinedError } from '@urql/svelte'

  import { LayoutContext } from '$/components'
  import { filterShadow, text } from '$/lib'

  export let action: string = ''
  export let name: string
  export let formenctype: 'application/x-www-form-urlencoded' | 'multipart/form-data' =
    'application/x-www-form-urlencoded'
  export let message = 'Formularul a fost trimis cu succes!'
  export let explanation: string | undefined = undefined
  export let onSubmit: SubmitFn = defaultSubmitFn
  export let rows = 4
  export let cols = 2
  export let disabled = false
  export let hasTitle = true
  export let submitOnChange = false
  export let timeout = 10000

  const hasTitleStore = writable(hasTitle)
  $: $hasTitleStore = hasTitle
  const disabledStore = writable(disabled)
  $: $disabledStore = disabled

  let form: HTMLFormElement

  export const focus = () => form.querySelector('input')?.focus()

  const submitStatus = createStatusStore()

  setForm({
    submitStatus,
    formenctype,
    rows,
    cols,
    disabled: disabledStore,
    hasTitle: hasTitleStore,
  })

  const submitFn = submit(
    onSubmit,
    { action, method: 'POST', message, explanation, timeout },
    submitStatus
  )

</script>

<LayoutContext let:theme>
  <form
    {action}
    method="POST"
    {name}
    id={name}
    {formenctype}
    {disabled}
    on:change={() => submitOnChange && submitFn(form)}
    bind:this={form}
    class="col-span-{3 * cols} row-span-{rows + 2 * +hasTitle} grid grid-rows-{rows +
      2 * +hasTitle} grid-cols-{3 * cols} gap-y-sm {filterShadow[theme]}"
    on:submit|preventDefault={() => submitFn(form)}>
    <fieldset class="col-span-{3 * cols} row-span-{rows + -!hasTitle}">
      <div
        class="grid grid-cols-{cols} grid-rows-{rows +
          -!hasTitle} gap-x-md gap-y-sm w-full h-full grid-flow-col font-sans antialiased">
        {#if hasTitle}
          <legend class="col-span-{cols} text-md self-center {text[theme]}">
            <slot name="legend" />
          </legend>
        {/if}
        <slot />
      </div>
    </fieldset>
    <slot name="actions" />
  </form>
</LayoutContext>
