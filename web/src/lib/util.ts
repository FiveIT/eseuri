import type { OperationResult } from '@urql/svelte'
import { rem } from './globals'

export const px = (v: number) => `${rem * v}`

export function handleGraphQLResponse<Data, T>(
  // eslint-disable-next-line no-unused-vars
  getter: (resp: Data) => T
  // eslint-disable-next-line no-unused-vars
): (resp: OperationResult<Data>) => T {
  return response => {
    if (response.error) {
      throw response.error
    }

    return getter(response.data!)
  }
}
