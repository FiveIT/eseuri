import type { DocumentNode } from 'graphql'
import type { Client, OperationResult, TypedDocumentNode } from '@urql/svelte'
import { from } from 'rxjs'
import { map } from 'rxjs/operators'
import { rem } from './globals'

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
  vars: Variables
) {
  return from(client.query(query, vars).toPromise()).pipe(map(handleGraphQLResponse(v => v)))
}

export function fromMutation<Result, Variables extends object>(
  client: Client,
  mutation: DocumentNode | TypedDocumentNode<Result, Variables> | string,
  vars: Variables
) {
  return from(client.mutation(mutation, vars).toPromise()).pipe(map(handleGraphQLResponse(v => v)))
}
