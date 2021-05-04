import { authToken } from '@tmaxmax/svelte-auth0'
import { get } from 'svelte/store'
import client from '$/graphql/client'
import { USER_UPDATED_AT } from '$/graphql/queries'
import type { CombinedError } from '@urql/svelte'

import { from, firstValueFrom } from 'rxjs'
import { map } from 'rxjs/operators'
import { handleGraphQLResponse } from './util'

export const getHeaders = () => {
  const token = get(authToken)

  if (token) {
    return { headers: { Authorization: `Bearer ${token}` } }
  }

  return {}
}

export const isRegistered = () =>
  firstValueFrom(
    from(
      client.query(USER_UPDATED_AT, undefined, { requestPolicy: 'network-only' }).toPromise()
    ).pipe(map(handleGraphQLResponse(v => v!.users[0].updated_at !== null)))
  )

export const internalErrorNotification = {
  status: 'error',
  message: 'Ceva neașteptat s-a întâmplat.',
  explanation: `Este o eroare internă, revino mai târziu - o vom rezolva în curând!`,
} as const

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

      const [err] = arg.graphQLErrors

      switch (err.extensions?.code) {
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
          console.error({ graphQLError: arg, err })

          this.message = internalErrorNotification.message
          this.explanation = internalErrorNotification.status
      }
    }
  }
}
