import { authToken } from '@tmaxmax/svelte-auth0'
import { get } from 'svelte/store'
import client from '$/graphql/client'
import type { Data, UserUpdatedAt, Vars } from '$/graphql/types'
import { USER_UPDATED_AT } from '$/graphql/queries'

const endpoint = import.meta.env.VITE_FUNCTIONS_URL as string

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

export class RequestError extends Error {
  // eslint-disable-next-line no-unused-vars
  constructor(
    public readonly message: string,
    public readonly explanation: string
  ) {
    super(message)
  }
}

const messages: Record<number, string> = {
  '400': 'Formularul trimis este invalid.',
  '401': 'Nu ești autorizat pentru a încărca o lucrare.',
  '500': 'A apărut o eroare internă, încearcă mai târziu.',
}

export async function uploadWork(form: FormData): Promise<number> {
  const res = await fetch(`${endpoint}/upload`, {
    body: form,
    method: 'POST',
    ...getHeaders(),
    cache: 'no-cache',
  })

  if (!res.ok) {
    const { error } = await res.json()

    throw new RequestError(
      messages[res.status] || 'Încărcarea lucrării a eșuat.',
      error
    )
  }

  const { id } = await res.json()

  return id
}
