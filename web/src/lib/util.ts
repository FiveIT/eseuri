import type { DocumentNode } from 'graphql'
import type { Client, OperationResult, TypedDocumentNode, OperationContext } from '@urql/svelte'
import { CombinedError } from '@urql/svelte'
import { from } from 'rxjs'
import { map } from 'rxjs/operators'

import { rem, RequestError, internalErrorNotification } from '.'
import type { FullNamer, MessagesRecord } from '.'

export const px = (v: number) => `${rem * v}`

export function handleGraphQLResponse<Data, T>(
  // eslint-disable-next-line no-unused-vars
  getter: (resp: Data) => T = (): T => undefined as any
  // eslint-disable-next-line no-unused-vars
): (resp: OperationResult<Data>) => T {
  return response => {
    if (response.error) {
      throw response.error
    }

    return getter(response.data!)
  }
}

export function graphQLSeed(): `${number}` {
  return `${Math.random()}` as const
}

export function fromQuery<Result = any, Variables extends object = {}>(
  client: Client,
  query: DocumentNode | TypedDocumentNode<Result, Variables> | string,
  vars?: Variables,
  context?: Partial<OperationContext>
) {
  return from(client.query(query, vars, context).toPromise()).pipe(
    map(handleGraphQLResponse(v => v!))
  )
}

export function fromMutation<Result, Variables extends object = {}>(
  client: Client,
  mutation: DocumentNode | TypedDocumentNode<Result, Variables> | string,
  vars?: Variables,
  context?: Partial<OperationContext>
) {
  return from(client.mutation(mutation, vars, context).toPromise()).pipe(
    map(handleGraphQLResponse(v => v!))
  )
}

export function getName({ first_name, middle_name, last_name }: FullNamer) {
  return `${first_name} ${middle_name ? `${middle_name} ` : ''}${last_name}`
}

// TODO: Maybe do this directly in the constructor?
// eslint-disable-next-line no-unused-vars
export function requestError(graphQLError: CombinedError): RequestError
// eslint-disable-next-line no-redeclare
export function requestError(
  // eslint-disable-next-line no-unused-vars
  messagesRecord: MessagesRecord,
  // eslint-disable-next-line no-unused-vars
  status: number,
  // eslint-disable-next-line no-unused-vars
  error?: string
): RequestError
// eslint-disable-next-line no-redeclare
export function requestError(
  arg: MessagesRecord | CombinedError,
  status?: number,
  error?: string
): RequestError {
  if (arg instanceof CombinedError) {
    return new RequestError(arg)
  }

  if (!status) {
    throw new Error('requestError: status must be defined')
  }

  const data: typeof arg[number] = arg[status] || internalErrorNotification

  if (typeof data === 'string') {
    return new RequestError(data, error)
  }

  return new RequestError(data.message, data.explanation || error)
}

export const clamp = (num: number, min: number, max: number) =>
  num <= min ? min : num >= max ? max : num

export const title = (s: string) =>
  s
    .split(/(\s+)/)
    .map(w => w[0].toLocaleUpperCase('ro-RO') + w.slice(1))
    .join('')
