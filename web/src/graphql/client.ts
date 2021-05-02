import {
  Client,
  dedupExchange,
  cacheExchange,
  fetchExchange,
  errorExchange,
  subscriptionExchange,
} from '@urql/svelte'
import { devtoolsExchange } from '@urql/devtools'
import { retryExchange } from '@urql/exchange-retry'
import { SubscriptionClient } from 'subscriptions-transport-ws'
import { getHeaders } from '$/lib/user'
import type { OperationDefinitionNode, FieldNode } from 'graphql'

const url = `${import.meta.env.VITE_HASURA_GRAPHQL_ENDPOINT}/v1/graphql`
const relayURL = `${import.meta.env.VITE_HASURA_GRAPHQL_ENDPOINT}/v1beta1/relay`

const getWSEndpoint = () => {
  const endpoint = url.slice(7)

  if (endpoint[0] === '/') {
    return `wss://${endpoint.slice(1)}`
  }

  return `ws://${endpoint}`
}

const subscriptionClient = new SubscriptionClient(getWSEndpoint(), {
  reconnect: true,
  lazy: true,
  connectionParams: getHeaders,
})

const exchanges = [
  dedupExchange,
  cacheExchange,
  errorExchange({
    onError(error, operation) {
      const query = operation.query.definitions.find(
        (def): def is OperationDefinitionNode => def.kind === 'OperationDefinition'
      )!
      const name =
        query.name?.value ||
        (query.selectionSet.selections[0] as FieldNode).name?.value ||
        'unknown'

      console.error(`Encountered GraphQL error on operation "${name}":\n`, {
        error,
      })
    },
  }),
  retryExchange({
    retryIf(error) {
      if (error.networkError) {
        return true
      }

      const [err] = error.graphQLErrors
      const code = err.extensions?.code || ''

      switch (code) {
        case 'invalid-jwt':
          return true
        case 'validation-failed':
          return error.message.includes(`field "updated_at" not found in type: 'users'`)
      }

      return false
    },
  }),
  fetchExchange,
  subscriptionExchange({
    forwardSubscription(operation) {
      return subscriptionClient.request(operation)
    },
  }),
]

if (import.meta.env.DEV) {
  exchanges.push(devtoolsExchange)
}

export default new Client({
  url,
  fetchOptions: getHeaders,
  exchanges,
})

export const relay = new Client({
  url: relayURL,
  fetchOptions: getHeaders,
  exchanges: exchanges.slice(-1),
})
