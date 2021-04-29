import { authToken } from '@tmaxmax/svelte-auth0'

const endpoint = import.meta.env.VITE_FUNCTIONS_URL as string

export const getHeaders = async (timeout: number = 10000) => {
  const token = await new Promise(resolve => {
    const handle = setTimeout(resolve, timeout, '')
    const unsubscribe = authToken.subscribe(v => {
      if (v) {
        resolve(v)
        clearTimeout(handle)
        unsubscribe()
      }
    })
  })

  if (token) {
    return { headers: { Authorization: `Bearer ${token}` } }
  }

  return {}
}

export const isRegistered = async (): Promise<boolean> => {
  const res = await fetch(`${endpoint}/isregistered`, {
    ...(await getHeaders()),
  })

  if (!res.ok) {
    return false
  }

  const info: { isRegistered: boolean } = await res.json()

  return info.isRegistered
}
