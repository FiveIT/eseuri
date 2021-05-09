import type { DocumentNode } from 'graphql'
import type { Client, OperationResult, TypedDocumentNode, OperationContext } from '@urql/svelte'
import { CombinedError } from '@urql/svelte'
import { from } from 'rxjs'
import { map } from 'rxjs/operators'

import { rem, RequestError, internalErrorNotification } from '.'
import type { FullNamer, MessagesRecord } from '.'
import { isNonNullable } from './types'

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

export const mapDefined = <T, R>(
  // eslint-disable-next-line no-unused-vars
  project: (v: NonNullable<T>, index: number) => R,
  nullValue: null | undefined = undefined
) => map<T, R | typeof nullValue>((v: T, i) => (isNonNullable(v) ? project(v, i) : nullValue))

function isDate(lhs: Date, rhs: Date): boolean {
  return (
    lhs.getDate() === rhs.getDate() &&
    lhs.getMonth() === rhs.getMonth() &&
    rhs.getFullYear() === lhs.getFullYear()
  )
}

const monthLookup = [
  ['ian', 'ianuarie'],
  ['feb', 'feburarie'],
  ['mar', 'martie'],
  ['apr', 'aprilie'],
  ['mai', 'mai'],
  ['iun', 'iunie'],
  ['iul', 'iulie'],
  ['aug', 'august'],
  ['sep', 'septembrie'],
  ['oct', 'octombrie'],
  ['nov', 'noiembrie'],
  ['dec', 'decembrie'],
]

export function formatDate(s: string, short?: boolean, html?: boolean): [string, 'la' | 'în'] {
  const date = new Date(s + '+00:00')
  const time = `${date.getHours()}:${date.getMinutes()}`

  const today = new Date()
  if (isDate(date, today)) {
    return [time, 'la']
  }

  const isCurrentYear = date.getFullYear() === today.getFullYear()
  const monthLength = +!!short

  return [
    `${date.getDate()} ${monthLookup[date.getMonth()][monthLength]}${
      isCurrentYear ? '' : date.getFullYear()
    }${html ? '<wbr />' : ' '}${time}`,
    'în',
  ]
}
