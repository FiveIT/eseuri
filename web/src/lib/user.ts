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

export const isRegistered = async (): Promise<boolean> => {
  const res = await fetch(`${endpoint}/isregistered`, getHeaders())

  if (!res.ok) {
    return false
  }

  const info: { isRegistered: boolean } = await res.json()

  return info.isRegistered
}
