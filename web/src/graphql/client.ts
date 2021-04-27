import {
  ApolloClient,
  split,
  InMemoryCache,
  HttpLink,
} from '@apollo/client/core'
import { WebSocketLink } from '@apollo/client/link/ws'
import { getMainDefinition } from '@apollo/client/utilities'
import { get } from 'svelte/store'
import { isAuthenticated, authToken } from '@tmaxmax/svelte-auth0'

const getEndpoint = () => {
  const endpoint = import.meta.env.VITE_HASURA_GRAPHQL_ENDPOINT as string

  if (endpoint.indexOf('http://') === 0) {
    return [
      `${endpoint}/v1/graphql`,
      `ws://${endpoint.slice(7)}/v1/graphql`,
    ] as const
  }

  return [
    `${endpoint}/v1/graphql`,
    `wss://${endpoint.slice(8)}/v1/graphql`,
  ] as const
}

const [httpEndpoint, wsEndpoint] = getEndpoint()

const getHeaders = () => {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }

  if (get(isAuthenticated)) {
    headers['Authorization'] = get(authToken)
  }

  return headers
}

const customFetch: typeof fetch = (uri, options) => {
  return fetch(uri, {
    ...options,
    headers: getHeaders(),
  })
}

const httpLink = new HttpLink({
  uri: httpEndpoint,
  fetch: customFetch,
})

const wsLink = new WebSocketLink({
  uri: wsEndpoint,
  options: {
    reconnect: true,
    lazy: true,
    connectionParams() {
      return { headers: getHeaders() }
    },
  },
})

const link = split(
  ({ query }) => {
    const op = getMainDefinition(query)
    return op.kind === 'OperationDefinition' && op.operation === 'subscription'
  },
  wsLink,
  httpLink
)

export default new ApolloClient({
  link,
  cache: new InMemoryCache(),
})
