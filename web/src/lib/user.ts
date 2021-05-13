import { get, writable } from 'svelte/store'
import { authToken } from '@tmaxmax/svelte-auth0'
import type { CombinedError } from '@urql/svelte'

import type { Notification, UserStatus } from '.'
import { requestError, fromStore, fromQuery } from '.'

import { Observable, of, concat, BehaviorSubject } from 'rxjs'
import { filter, switchMap, first, map, catchError } from 'rxjs/operators'
import { fromFetch } from 'rxjs/fetch'
import type { Writable } from 'svelte/store'

import client from '$/graphql/client'
import { SELF, USER_STATUS } from '$/graphql/queries'
import { fromSubscription, mapDefined } from './util'
import { isNonNullable } from './types'

const endpoint = `${import.meta.env.VITE_FUNCTIONS_URL}` as const

export const getHeaders = () => {
  const token = get(authToken)

  if (token) {
    return { headers: { Authorization: `Bearer ${token}` } }
  }

  return {}
}

export const internalErrorNotification = {
  status: 'error',
  message: 'Ceva neașteptat s-a întâmplat.',
  explanation: `Este o eroare internă, revino mai târziu - o vom rezolva în curând!`,
} as const

export type MessagesRecord = Record<number, string | Omit<Notification, 'status'>>

const statusErrorMessages: MessagesRecord = {
  400: {
    message: 'Datele de autentificare sunt invalide.',
    explanation: 'Încearcă să te reloghezi, probabil a expirat sesiunea.',
  },
  401: {
    message: 'Nu ești autorizat.',
    explanation: 'Conectează-te sau fă-ți un cont pentru a continua.',
  },
  404: {
    message: 'Utilizatorul tău nu a fost găsit.',
    explanation:
      'Ai făcut ceva tare ciudat ca să primești această eroare, încearcă să te reloghezi.',
  },
}

export const statusError: Writable<RequestError | null> = writable(null)

const fetchStatus = (): Observable<UserStatus | null> =>
  fromStore(authToken).pipe(
    filter(v => !!v),
    first(),
    switchMap(token =>
      fromFetch(`${endpoint}/user`, {
        headers: { Authorization: `Bearer ${token}` },
        selector: r => r.json().then(v => [v, r.ok, r.status] as const),
      }).pipe(
        switchMap(([data, ok, status]) => {
          if (ok) {
            return of(data)
          }

          statusError.set(requestError(statusErrorMessages, status))

          return of(null)
        }),
        catchError(() => {
          statusError.set(requestError(statusErrorMessages, 500))

          return of(null)
        })
      )
    )
  )

const status$ = concat(
  of(null),
  fetchStatus().pipe(
    switchMap(value => {
      if (value) {
        return fromSubscription(client, USER_STATUS, { id: value.id }).pipe(
          map(resp => (resp.users.length === 0 ? null : { ...resp.users[0], id: value.id })),
          mapDefined(
            ({ id, role, updated_at }): UserStatus => ({
              id,
              role,
              isRegistered: updated_at !== null,
            }),
            null
          ),
          catchError(err => {
            statusError.set(requestError(err as CombinedError))

            return of(null)
          })
        )
      }

      return of(value)
    })
  )
)

export const status = new BehaviorSubject<UserStatus | null>(null)

status$.subscribe(status)

export const self = concat(
  of(undefined),
  status.pipe(
    filter(isNonNullable),
    switchMap(({ id }) => fromQuery(client, SELF, { id })),
    map(v =>
      v.users[0] ? ({ found: true, user: v.users[0] } as const) : ({ found: false } as const)
    )
  )
)

export class RequestError extends Error {
  public readonly message: string
  public readonly explanation?: string

  // eslint-disable-next-line no-unused-vars
  constructor(graphQLError: CombinedError)
  // eslint-disable-next-line no-unused-vars
  constructor(message: string, explanation?: string)
  constructor(arg: CombinedError | string, explanation?: string) {
    if (typeof arg === 'string') {
      super(arg)

      this.message = arg
      this.explanation = explanation
    } else {
      super(arg.message)

      const err = arg.graphQLErrors.length
        ? arg.graphQLErrors[0]
        : (arg.networkError as Error & { extensions: { [k: string]: any } })

      // TODO: Better error messages
      switch (err?.extensions?.code) {
        case 'permission-error':
        case 'constraint-violation':
          var [match] = err.message.match(/(?<=")[^"]*(?="[^"]*$)/)!
          this.message = 'Datele trimise sunt incorecte!'
          this.explanation = match
          break
        case 'invalid-jwt':
          this.message = 'Datele tale de autentificare sunt invalide sau expirate.'
          this.explanation = 'Încearcă să reîmprospătezi pagina sau să te reconectezi.'
          break
        default:
          this.message = internalErrorNotification.message
          this.explanation = internalErrorNotification.status
      }
    }
  }
}
