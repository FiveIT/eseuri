import { authToken } from '@tmaxmax/svelte-auth0'
import { get } from 'svelte/store'
import client from '$/graphql/client'
import type { Data, UserUpdatedAt, Vars } from '$/graphql/types'
import { USER_UPDATED_AT } from '$/graphql/queries'

// const endpoint = import.meta.env.VITE_FUNCTIONS_URL as string

export const getHeaders = () => {
  const token = get(authToken)

  if (token) {
    return { headers: { Authorization: `Bearer ${token}` } }
  }

  return {}
}

export const isRegistered = async (): Promise<boolean> => {
  const resp = await client
    .query<Data<UserUpdatedAt>, Vars<UserUpdatedAt>>(
      USER_UPDATED_AT,
      undefined,
      { requestPolicy: 'network-only' }
    )
    .toPromise()

  if (resp.error) {
    throw resp.error
  }

  return resp.data!.users[0].updated_at !== null
}
