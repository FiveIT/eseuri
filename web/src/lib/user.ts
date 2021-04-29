import { authToken } from '@tmaxmax/svelte-auth0'
import { get } from 'svelte/store'

const endpoint = import.meta.env.VITE_FUNCTIONS_URL as string

export const getHeaders = () => {
  const token = get(authToken)

  if (token) {
    return { headers: { Authorization: `Bearer ${token}` } }
  }

  return {}
}

export class RequestError extends Error {
  // eslint-disable-next-line no-unused-vars
  constructor(public status: number, public message: string) {
    super(message)
  }
}

export const isRegistered = async (): Promise<boolean> => {
  const res = await fetch(`${endpoint}/isregistered`, getHeaders())

  if (!res.ok) {
    if (res.status === 400 || res.status === 401) {
      return false
    }

    const { error } = await res.json()

    throw new RequestError(res.status, error)
  }

  const { isRegistered } = await res.json()

  return isRegistered
}
